import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import '../main.dart';
import 'complete_profile_screen.dart';
import '../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  String verificationId = "";

  Future<void> sendOTP() async {
    print("PHONE = +91${phoneController.text.trim()}");

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91${phoneController.text.trim()}",

      verificationCompleted: (PhoneAuthCredential credential) async {
        print("AUTO VERIFIED");
        await FirebaseAuth.instance.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        print("ERROR CODE = ${e.code}");
        print("ERROR MESSAGE = ${e.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Verification Failed")),
        );
      },

      codeSent: (String verId, int? resendToken) {
        print("OTP SENT SUCCESSFULLY");
        verificationId = verId;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(verificationId: verificationId),
          ),
        );
      },

      codeAutoRetrievalTimeout: (String verId) {
        print("TIMEOUT");
        verificationId = verId;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield, size: 100, color: Colors.blue),

              const SizedBox(height: 20),

              const Text(
                "SafeSphere Login",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "Enter Phone Number",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(onPressed: sendOTP, child: const Text("Send OTP")),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  final String verificationId;

  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();

  Future<void> verifyOTP() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      print("LOGIN SUCCESS");

      bool completed = await FirestoreService().isProfileCompleted();

      if (completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print("OTP ERROR = ${e.code}");
      print("MESSAGE = ${e.message}");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter OTP")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: verifyOTP,
              child: const Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
