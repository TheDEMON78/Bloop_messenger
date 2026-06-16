import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneCtrl = TextEditingController();
  String _countryCode = '+33';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().addListener(_onAuthStateChange);
    });
  }

  @override
  void dispose() {
    try {
      context.read<AuthProvider>().removeListener(_onAuthStateChange);
    } catch (_) {}
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onAuthStateChange() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.state == AuthState.otpSent) {
      final phone = '$_countryCode${_cleanPhone(_phoneCtrl.text)}';
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)),
      );
    } else if (auth.state == AuthState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erreur lors de l\'envoi du code'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _cleanPhone(String input) {
    String digits = input.trim().replaceAll(RegExp(r'\s+'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  Future<void> _send() async {
    final cleaned = _cleanPhone(_phoneCtrl.text);
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entre ton numéro de téléphone'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final phone = '$_countryCode$cleaned';
    await context.read<AuthProvider>().sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Bloop',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entre ton numéro de téléphone',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontSize: 16),
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _countryCode,
                    dropdownColor: cs.surfaceContainerHigh,
                    style: TextStyle(color: cs.onSurface),
                    items: const [
                      DropdownMenuItem(value: '+33', child: Text('+33 🇫🇷')),
                      DropdownMenuItem(value: '+1', child: Text('+1 🇺🇸')),
                      DropdownMenuItem(value: '+44', child: Text('+44 🇬🇧')),
                      DropdownMenuItem(value: '+49', child: Text('+49 🇩🇪')),
                      DropdownMenuItem(value: '+34', child: Text('+34 🇪🇸')),
                      DropdownMenuItem(value: '+39', child: Text('+39 🇮🇹')),
                      DropdownMenuItem(value: '+32', child: Text('+32 🇧🇪')),
                      DropdownMenuItem(value: '+41', child: Text('+41 🇨🇭')),
                      DropdownMenuItem(value: '+55', child: Text('+55 🇧🇷')),
                      DropdownMenuItem(value: '+91', child: Text('+91 🇮🇳')),
                    ],
                    onChanged: (v) => setState(() => _countryCode = v!),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: cs.onSurface, fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: '6 12 34 56 78',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      auth.state == AuthState.loading ? null : _send,
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
                              strokeWidth: 2, color: cs.onPrimary),
                        )
                      : const Text('Continuer',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
