import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:renthive/screens/auth/onbarding_screen.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return const MainNavigation();
        }

        return const OnboardingScreen();
      },
    );
  }
}