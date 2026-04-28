import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/custom_primary_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await ref.read(authServiceProvider).signInWithEmail(email, password);
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _googleAuthMock() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Auth requires explicit SHA-1 token linking. Please use Email/Password right now!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Icon
              const Icon(
                Icons.volunteer_activism,
                size: 80,
                color: Color(0xFF2E7D32),
              ).animate().fade(duration: 500.ms).scale(delay: 200.ms),
              const SizedBox(height: 32),
              
              // Welcome Text
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 8),
              
              Text(
                'Sign in to continue making an impact.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 48),

              // Email Field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ).animate().fade(delay: 500.ms).slideX(begin: -0.1, end: 0),
              
              const SizedBox(height: 24),

              // Password Field
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: Icon(Icons.visibility_off),
                ),
                obscureText: true,
              ).animate().fade(delay: 600.ms).slideX(begin: -0.1, end: 0),
              
              const SizedBox(height: 16),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot Password?'),
                ),
              ).animate().fade(delay: 700.ms),

              const SizedBox(height: 32),

              // Custom Primary Login Button
              CustomPrimaryButton(
                text: 'Sign In',
                onPressed: _loginWithEmail,
                isLoading: _isLoading,
              ).animate().fade(delay: 800.ms).scale(),

              const SizedBox(height: 32),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('OR', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ).animate().fade(delay: 900.ms),

              const SizedBox(height: 32),

              // Google Sign In
              OutlinedButton.icon(
                onPressed: _googleAuthMock,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                icon: const FaIcon(FontAwesomeIcons.google, size: 24, color: Colors.red),
                label: const Text(
                  'Sign in with Google',
                  style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ).animate().fade(delay: 1000.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 10),

              // Sign Up route
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/onboarding');
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ).animate().fade(delay: 1100.ms),
            ],
          ),
        ),
      ),
    );
  }
}
