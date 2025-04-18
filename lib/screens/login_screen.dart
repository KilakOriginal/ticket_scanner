import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_scanner/localisation/locales.dart';
import 'package:ticket_scanner/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (response.user != null && mounted) {
        Navigator.pop(context); // Close the login screen
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocaleData.loginError.getString(context),
                style: TextStyle(color: textLightColour),
              ),
              backgroundColor: errorColour,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e', style: TextStyle(color: textLightColour)),
            backgroundColor: errorColour,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: LocaleData.emailTitle.getString(context),
              ),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: LocaleData.passwordTitle.getString(context),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              child: Text(LocaleData.loginPrompt.getString(context)),
            ),
          ],
        ),
      ),
    );
  }
}
