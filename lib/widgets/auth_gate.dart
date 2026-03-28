import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/patient_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isInitializing) {
      return const _AuthLoadingScreen();
    }

    if (authProvider.isAuthenticated) {
      return const PatientDashboard();
    }

    return const LoginScreen();
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color.fromARGB(255, 110, 101, 168),
            ),
            SizedBox(height: 16),
            Text(
              'Preparing app...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 37, 101, 146),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
