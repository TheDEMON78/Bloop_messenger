import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contacts_provider.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _phoneCtrl = TextEditingController();
  bool _searching = false;
  String? _foundName;
  String? _foundUid;
  String? _notFound;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _notFound = null;
      _foundName = null;
      _foundUid = null;
    });
    final user = await context
        .read<ContactsProvider>()
        .findUserByPhone(_phoneCtrl.text.trim());
    setState(() => _searching = false);
    if (user == null) {
      setState(() => _notFound = 'Aucun utilisateur trouvé');
    } else {
      setState(() {
        _foundName = user.displayName;
        _foundUid = user.uid;
      });
    }
  }

  Future<void> _add() async {
    if (_foundUid == null || _foundName == null) return;
    final myUid = context.read<AuthProvider>().user?.uid;
    if (myUid == null) return;
    await context.read<ContactsProvider>().addContact(
          myUid,
          ContactModel(
            uid: _foundUid!,
            phone: _phoneCtrl.text.trim(),
            displayName: _foundName!,
          ),
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un contact')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rechercher par numéro de téléphone',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: cs.onSurface),
                    decoration: const InputDecoration(
                      hintText: '+33612345678',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _searching ? null : _search,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary),
                  child: _searching
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.onPrimary))
                      : const Text('Chercher'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_notFound != null)
              Text(_notFound!,
                  style: const TextStyle(color: Colors.redAccent)),
            if (_foundName != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: cs.surfaceContainerHigh,
                  child: Text(
                    _foundName![0].toUpperCase(),
                    style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(_foundName!,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(_phoneCtrl.text.trim(),
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.38))),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _add,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ajouter le contact',
                      style:
                          TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
