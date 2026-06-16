import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/phone_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Supprimer mon compte',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: const Text(
          'Cette action est irréversible.\n\nTon profil, tes messages et tes contacts seront définitivement supprimés.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer définitivement',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.delete();
      if (!context.mounted) return;
      await context.read<AuthProvider>().signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PhoneScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Pour supprimer ton compte, reconnecte-toi d\'abord.'),
            backgroundColor: Color(0xFF1A1A2E),
          ),
        );
        await context.read<AuthProvider>().signOut();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PhoneScreen()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Erreur lors de la suppression'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 52,
                backgroundColor: const Color(0xFF1A1A2E),
                child: Text(
                  (user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0]
                          : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                      fontSize: 40,
                      color: Color(0xFF00F5FF),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user?.displayName ?? user?.phoneNumber ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                user?.phoneNumber ?? '',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
            const SizedBox(height: 40),
            const Divider(color: Color(0xFF1A1A2E)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white54),
              title: const Text('Se déconnecter',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                await context.read<AuthProvider>().signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PhoneScreen()),
                  (_) => false,
                );
              },
            ),
            const Divider(color: Color(0xFF1A1A2E)),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Supprimer mon compte',
                  style: TextStyle(color: Colors.redAccent)),
              subtitle: const Text('Action irréversible',
                  style:
                      TextStyle(color: Colors.redAccent, fontSize: 12)),
              onTap: () => _deleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}
