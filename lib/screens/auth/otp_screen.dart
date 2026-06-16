import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'profile_setup_screen.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(_otpCtrl.text.trim());
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Code invalide'),
            backgroundColor: Colors.redAccent,
          ));
      return;
    }
    if (auth.state == AuthState.profileIncomplete) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const ProfileSetupScreen()));
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Code envoyé au\n${widget.phone}',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontSize: 16),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 32,
                    letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.24),
                      fontSize: 32,
                      letterSpacing: 12),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      auth.state == AuthState.loading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.state == AuthState.loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.onPrimary))
                      : const Text('Vérifier',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
