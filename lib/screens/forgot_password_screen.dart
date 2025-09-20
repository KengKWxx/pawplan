import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ลืมรหัสผ่าน")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "ใส่อีเมลของคุณเพื่อรีเซ็ตรหัสผ่าน",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                // TODO: Firebase reset password
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ยังไม่ได้เชื่อม Firebase")),
                );
              },
              child: const Text("ส่งลิงก์รีเซ็ต"),
            ),
          ],
        ),
      ),
    );
  }
}
