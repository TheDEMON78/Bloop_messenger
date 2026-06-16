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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Ton profil',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cs.primary),
              ),
              const SizedBox(height: 8),
              Text('Choisis un nom d\'affichage',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 40),
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: cs.surfaceContainerHigh,
                      child: Icon(Icons.person,
                          size: 52, color: cs.primary),
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: cs.primary,
                      child: Icon(Icons.camera_alt,
                          size: 16, color: cs.onPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: cs.onSurface, fontSize: 18),
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _statusCtrl,
                style: TextStyle(color: cs.onSurface),
                decoration: const InputDecoration(
                  labelText: 'Statut (optionnel)',
                  hintText: 'Disponible',
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
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
