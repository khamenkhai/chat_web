import 'package:chat_web/chat_service/models/message_models.dart' as mm;
import 'package:chat_web/chat_service/service/chat_service.dart';
import 'package:chat_web/controller/profile_provider.dart';
import 'package:chat_web/core/utils/format_last_seen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chat_web/core/component/loading_widget.dart';
import 'package:chat_web/core/utils/context_extension.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class ProfileUpdatePage extends ConsumerStatefulWidget {
  const ProfileUpdatePage({super.key});

  @override
  ConsumerState<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends ConsumerState<ProfileUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  bool switchValue = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);

    // Update controllers when data loads
    profileState.whenData((user) {
      if (user != null) {
        _firstNameController.text = user.firstName ?? '';
        _lastNameController.text = user.lastName ?? '';
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        centerTitle: true,
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (user) => _buildProfileForm(user, profileState),
      ),
    );
  }

  Widget _buildProfileForm(mm.User? user, profileState) {
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 10,
                  color: Theme.of(context).shadowColor.withAlpha(25),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: user.imageUrl != null
                              ? NetworkImage(user.imageUrl!)
                              : null,
                          child: user.imageUrl == null
                              ? const Icon(IconlyLight.profile, size: 60)
                              : null,
                        ),
                        IconButton.filled(
                          onPressed: () => ref
                              .read(profileControllerProvider.notifier)
                              .uploadImage(),
                          style:
                              FilledButton.styleFrom(padding: EdgeInsets.zero),
                          icon: Icon(
                            IconlyLight.edit,
                            size: 16,
                            color: context.cardColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: Icon(IconlyLight.profile),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        prefixIcon: Icon(IconlyLight.profile),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Switch(
                        value: switchValue,
                        onChanged: (value) {
                          setOnline(value);
                          setState(() {
                            switchValue = value;
                          });
                        }),
                    FutureBuilder(
                      future: FyreChat.instance.getUserById(
                          FirebaseAuth.instance.currentUser?.uid ?? ""),
                      builder: (context, snapshot) {
                        final bool isOnline = snapshot.data?.isOnline ?? false;
                        return Text(
                          isOnline
                              ? "Active Now"
                              : formatLastSeen(snapshot.data?.lastSeen),
                          style: const TextStyle(fontSize: 12, height: 0),
                        );
                      },
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: profileState.isLoading
                          ? const LoadingWidget()
                          : FilledButton(
                              onPressed: _submitForm,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(profileControllerProvider.notifier).updateProfile(
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      }
    }
  }

  void setOnline(bool online) {
    FyreChat.instance.setOnline(online);
  }
}
