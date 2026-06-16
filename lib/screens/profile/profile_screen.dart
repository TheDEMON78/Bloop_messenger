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
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    final statusCtrl = TextEditingController(text: user?.status ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Modifier le profil',
            style: TextStyle(color: cs.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: cs.onSurface),
              maxLength: 30,
              decoration:
                  const InputDecoration(labelText: 'Nom affiché'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: statusCtrl,
              style: TextStyle(color: cs.onSurface),
              maxLength: 60,
              decoration: const InputDecoration(
                  labelText: 'Statut (ex: Disponible)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
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
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer mon compte',
            style: TextStyle(color: Colors.redAccent)),
        content: Text(
          'Cette action est irréversible.\n\nTon profil, tes messages et tes contacts seront définitivement supprimés.',
          style:
              TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.54))),
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
    final cs = Theme.of(context).colorScheme;
    final phone =
        FirebaseAuth.instance.currentUser?.phoneNumber ?? user?.phone ?? '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const SizedBox(height: 16),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: cs.surfaceContainerHigh,
                    child: Text(
                      _initials,
                      style: TextStyle(
                          fontSize: 42,
                          color: cs.primary,
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
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context)
                                  .scaffoldBackgroundColor,
                              width: 2),
                        ),
                        child: Icon(Icons.edit,
                            color: cs.onPrimary, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: user == null
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.primary),
                    )
                  : Text(
                      user!.displayName.isNotEmpty
                          ? user!.displayName
                          : 'Sans nom',
                      style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                phone,
                style: TextStyle(color: cs.primary, fontSize: 15),
              ),
            ),
            if (user?.status?.isNotEmpty == true) ...[  
              const SizedBox(height: 4),
              Center(
                child: Text(
                  user!.status!,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.54),
                      fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _editProfile(context),
              icon: Icon(Icons.edit_outlined, color: cs.primary, size: 18),
              label: Text('Modifier le profil',
                  style: TextStyle(color: cs.primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.primary, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: cs.surfaceContainerHigh, thickness: 1),
            _InfoTile(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                value: phone),
            if (user?.status?.isNotEmpty == true)
              _InfoTile(
                  icon: Icons.info_outline,
                  label: 'Statut',
                  value: user!.status!),
            Divider(color: cs.surfaceContainerHigh, thickness: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.logout,
                  color: cs.onSurface.withValues(alpha: 0.54), size: 22),
              title: Text('Se déconnecter',
                  style: TextStyle(color: cs.onSurface)),
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
            Divider(color: cs.surfaceContainerHigh, thickness: 1),
            const SizedBox(height: 8),
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.38),
                      fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(color: cs.onSurface, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
