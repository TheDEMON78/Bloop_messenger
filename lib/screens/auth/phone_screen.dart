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
    // Remove listener safely
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
    // Remove all spaces
    String digits = input.trim().replaceAll(RegExp(r'\s+'), '');
    // Remove leading 0 (French numbers: 0612345678 -> 612345678)
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
    final auth = context.read<AuthProvider>();
    await auth.sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'Bloop',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00F5FF),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entre ton numéro de téléphone',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _countryCode,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
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
                      style:
                          const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: '6 12 34 56 78',
                        hintStyle: TextStyle(color: Colors.white30),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00F5FF)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFF00F5FF), width: 2),
                        ),
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
                    backgroundColor: const Color(0xFF00F5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.state == AuthState.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
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
