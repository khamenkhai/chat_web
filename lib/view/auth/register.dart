import 'package:chat_web/core/component/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chat_web/controller/auth_provider.dart';
import 'package:chat_web/core/const/size_const.dart';
import 'package:iconly/iconly.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final imageUrlController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    imageUrlController.dispose();
    emailController.dispose();
    passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    ref.read(authControllerProvider.notifier).signUpWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          imageUrl: imageUrlController.text.trim(),
        );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    if (authState is AuthError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(authState.message);
      });
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: SizeConst.kBorderRadius,
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 2),
                        blurRadius: 10,
                        color: Theme.of(context)
                            .shadowColor
                            .withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  child: _buildRegisterForm(context, isLoading),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'Create an account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Fill the details to get started',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(IconlyLight.profile),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter first name' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(IconlyLight.profile),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter last name' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  prefixIcon: Icon(IconlyLight.image),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter image URL' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(IconlyLight.message),
                ),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter email';
                  if (!value.contains('@')) return 'Enter valid email';
                  return null;
                },
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                focusNode: _passwordFocusNode,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(IconlyLight.lock),
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter password';
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => isLoading ? null : _register(),
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isLoading ? null : _register,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: SizeConst.kHorizontalPadding,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20, height: 20, child: LoadingWidget())
                    : const Text('Register'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        context.go('/login');
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16,horizontal: SizeConst.kHorizontalPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
