import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_service.dart';
import 'complete_profile_screen.dart';
import 'login_screen.dart';
import '../main.dart';

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: FirestoreService().isProfileCompleted(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Login check
        if (FirebaseAuth.instance.currentUser == null) {
          return const LoginScreen();
        }

        // Profile complete
        if (snapshot.data == true) {
          return const Home();
        }

        // Profile incomplete
        return const CompleteProfileScreen();
      },
    );
  }
}
