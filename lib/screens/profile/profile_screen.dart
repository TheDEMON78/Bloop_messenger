import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../auth/phone_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return StreamBuilder<UserModel?>(
      stream: FirestoreService().userStream(uid),
      builder: (context, snap) {
        final user = snap.data;
        return _ProfileView(user: user, uid: uid);
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  final UserModel? user;
  final String uid;

  const _ProfileView({required this.user, required this.uid});

  String get _initials {
    final name = user?.displayName ?? '';
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _editProfile(BuildContext context) async {
    final nameCtrl =
        TextEditingController(text: user?.displayName ?? '');
    final statusCtrl =
        TextEditingController(text: user?.status ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Modifier le profil',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'Nom affiché',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00F5FF))),
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF00F5FF), width: 2)),
                counterStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: statusCtrl,
              style: const TextStyle(color: Colors.white),
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Statut (ex: Disponible)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00F5FF))),
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF00F5FF), width: 2)),
                counterStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F5FF),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final newName = nameCtrl.text.trim();
    if (newName.isEmpty) return;

    await FirestoreService().updateProfile(
      uid: uid,
      displayName: newName,
      status: statusCtrl.text.trim(),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Supprimer mon compte',
            style: TextStyle(color: Colors.redAccent)),
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
      final fireUser = FirebaseAuth.instance.currentUser!;
      await FirestoreService().deleteUserData(uid);
      await fireUser.delete();
      if (!context.mounted) return;
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
            content:
                Text('Reconnecte-toi d\'abord pour supprimer ton compte.'),
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
    final phone =
        FirebaseAuth.instance.currentUser?.phoneNumber ?? user?.phone ?? '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const SizedBox(height: 16),

            // Avatar + edit button
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: const Color(0xFF112240),
                    child: Text(
                      _initials,
                      style: const TextStyle(
                          fontSize: 42,
                          color: Color(0xFF00F5FF),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => _editProfile(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F5FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF0A0A0F), width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.black, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Name
            Center(
              child: user == null
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00F5FF)),
                    )
                  : Text(
                      user!.displayName.isNotEmpty
                          ? user!.displayName
                          : 'Sans nom',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 6),

            // Phone
            Center(
              child: Text(
                phone,
                style:
                    const TextStyle(color: Color(0xFF00F5FF), fontSize: 15),
              ),
            ),

            const SizedBox(height: 6),

            // Status
            if (user?.status?.isNotEmpty == true)
              Center(
                child: Text(
                  user!.status!,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                ),
              ),

            const SizedBox(height: 32),

            // Edit profile button
            OutlinedButton.icon(
              onPressed: () => _editProfile(context),
              icon: const Icon(Icons.edit_outlined,
                  color: Color(0xFF00F5FF), size: 18),
              label: const Text('Modifier le profil',
                  style: TextStyle(color: Color(0xFF00F5FF))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00F5FF), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(color: Color(0xFF1A1A2E), thickness: 1),

            // Info tiles
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Téléphone',
              value: phone,
            ),
            if (user?.status?.isNotEmpty == true)
              _InfoTile(
                icon: Icons.info_outline,
                label: 'Statut',
                value: user!.status!,
              ),

            const Divider(color: Color(0xFF1A1A2E), thickness: 1),
            const SizedBox(height: 8),

            // Logout
            ListTile(
              leading:
                  const Icon(Icons.logout, color: Colors.white54, size: 22),
              title: const Text('Se déconnecter',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                await context.read<AuthProvider>().signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const PhoneScreen()),
                  (_) => false,
                );
              },
            ),

            const Divider(color: Color(0xFF1A1A2E), thickness: 1),
            const SizedBox(height: 8),

            // Delete account
            ListTile(
              leading: const Icon(Icons.delete_forever,
                  color: Colors.redAccent, size: 22),
              title: const Text('Supprimer mon compte',
                  style: TextStyle(color: Colors.redAccent)),
              subtitle: const Text('Action irréversible',
                  style:
                      TextStyle(color: Colors.redAccent, fontSize: 11)),
              onTap: () => _deleteAccount(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00F5FF), size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
