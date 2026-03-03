import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EBF0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Heart Icon
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B7EF8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2B7EF8).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              // Title
              const Text(
                'CardioCare',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3B5D),
                ),
              ),

              const SizedBox(height: 12),

              // Tagline
              const Text(
                'Safe Anticoagulation. Smarter Recovery.',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF2B7EF8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B7EF8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign Up Button
              // SizedBox(
              //   width: double.infinity,
              //   height: 56,
              //   child: OutlinedButton(
              //     onPressed: () {
              //       Navigator.pushNamed(context, '/register');
              //     },
              //     style: OutlinedButton.styleFrom(
              //       foregroundColor: const Color(0xFF2B7EF8),
              //       side: const BorderSide(color: Color(0xFF2B7EF8), width: 2),
              //       backgroundColor: Colors.white,
              //       elevation: 0,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(16),
              //       ),
              //     ),
              //     child: const Text(
              //       'Sign Up',
              //       style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 40),

              // Trust Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTrustIndicator('Clinically Trusted'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      '•',
                      style: TextStyle(color: Color(0xFF2B7EF8), fontSize: 20),
                    ),
                  ),
                  _buildTrustIndicator('Secure & Private'),
                ],
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustIndicator(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF00C853),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A3B5D),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
