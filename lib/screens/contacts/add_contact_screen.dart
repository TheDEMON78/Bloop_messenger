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
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un contact')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rechercher par numéro de téléphone',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style:
                        const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '+33612345678',
                      hintStyle:
                          TextStyle(color: Colors.white30),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF00F5FF))),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF00F5FF),
                              width: 2)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _searching ? null : _search,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F5FF),
                      foregroundColor: Colors.black),
                  child: _searching
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black))
                      : const Text('Chercher'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_notFound != null)
              Text(_notFound!,
                  style:
                      const TextStyle(color: Colors.redAccent)),
            if (_foundName != null) ...[  
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1A1A2E),
                  child: Text(
                    _foundName![0].toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF00F5FF),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(_foundName!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(_phoneCtrl.text.trim(),
                    style:
                        const TextStyle(color: Colors.white38)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _add,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5FF),
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ajouter le contact',
                      style: TextStyle(
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
