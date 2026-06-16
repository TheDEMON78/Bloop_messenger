import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _statusCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await context.read<AuthProvider>().saveProfile(name);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'Ton profil',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00F5FF)),
              ),
              const SizedBox(height: 8),
              const Text('Choisis un nom d\'affichage',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 40),
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 52,
                      backgroundColor: Color(0xFF1A1A2E),
                      child: Icon(Icons.person,
                          size: 52, color: Color(0xFF00F5FF)),
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF00F5FF),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: Color(0xFF00F5FF)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF00F5FF))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF00F5FF), width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _statusCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Statut (optionnel)',
                  labelStyle: TextStyle(color: Colors.white54),
                  hintText: 'Disponible',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF00F5FF))),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('C\'est parti !',
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
