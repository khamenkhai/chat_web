import 'package:chat_web/controller/auth_provider.dart';
import 'package:chat_web/view/auth/login.dart';
import 'package:chat_web/view/auth/register.dart';
import 'package:chat_web/view/chat/chat.dart';
import 'package:chat_web/view/profile/profile.dart';
import 'package:chat_web/view/rooms/rooms.dart';
import 'package:chat_web/view/users/users.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>(
  (ref) {
    final authState = ref.watch(authControllerProvider);

    return GoRouter(
      debugLogDiagnostics: true,
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authState is AuthAuthenticated;
        // final isAuthRoute = state.matchedLocation.startsWith('/auth');
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        if (isAuthenticated && isAuthRoute) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const RoomsPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UsersPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileUpdatePage(),
        ),
        // GoRoute(
        //   path: '/test',
        //   builder: (context, state) =>  MessageScreen(),
        // ),
        GoRoute(
          path: '/chat/:roomId',
          builder: (context, state) {
            final roomId = state.pathParameters['roomId'] ?? "";
            return ChatPage(roomId: roomId);
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Error: ${state.error}'),
        ),
      ),
    );
  },
);
