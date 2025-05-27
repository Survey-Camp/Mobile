import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:survey_camp/shared/widgets/custom_navbar.dart';
import 'package:survey_camp/features/auth/signup/signup.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Timer timer;
  bool isEmailVerified = false;
  bool canResendEmail = false;

  @override
  void initState() {
    super.initState();
    isEmailVerified = auth.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }

    Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          canResendEmail = true;
        });
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    await auth.currentUser?.reload();

    setState(() {
      isEmailVerified = auth.currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer.cancel();
      await firestore.collection('users').doc(auth.currentUser?.uid).update({
        'isEmailVerified': true,
      });
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CustomBottomNavbar(),
        ),
      );
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = auth.currentUser;
      await user?.sendEmailVerification();

      setState(() {
        canResendEmail = false;
      });

      // Allow resending verification email after 30 seconds
      Timer(const Duration(seconds: 30), () {
        if (mounted) {
          setState(() {
            canResendEmail = true;
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 100,
              color: Color(0xFFFFC49F),
            ),
            const SizedBox(height: 24),
            Text(
              'Verify your email',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'We have sent a verification email to:\n${widget.email}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Click the link in the email to verify your account.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (!isEmailVerified)
              ElevatedButton(
                onPressed: canResendEmail ? sendVerificationEmail : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC49F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  canResendEmail
                      ? 'Resend Verification Email'
                      : 'Wait 30 seconds to resend',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                auth.signOut();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SignUpPage(),
                  ),
                );
              },
              child: Text(
                'Change Email',
                style: TextStyle(
                  color: Colors.grey[600],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
