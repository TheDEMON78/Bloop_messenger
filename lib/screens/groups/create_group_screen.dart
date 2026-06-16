import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contacts_provider.dart';
import '../chat/chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final Set<String> _selected = {};
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selected.isEmpty) return;
    setState(() => _creating = true);
    final myUid = context.read<AuthProvider>().user?.uid ?? '';
    final conv = await context.read<ChatProvider>().createGroup(
          creatorUid: myUid,
          groupName: name,
          memberUids: _selected.toList(),
        );
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) =>
              ChatScreen(conversation: conv, myUid: myUid)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final contacts = context.watch<ContactsProvider>().contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau groupe'),
        actions: [
          TextButton(
            onPressed: _creating ? null : _create,
            child: _creating
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.primary))
                : Text('Créer',
                    style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration:
                  const InputDecoration(labelText: 'Nom du groupe'),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Sélectionne des membres',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.54),
                      fontSize: 12)),
            ),
          ),
          Expanded(
            child: contacts.isEmpty
                ? Center(
                    child: Text('Aucun contact',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.38))))
                : ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (_, i) {
                      final c = contacts[i];
                      final isSelected = _selected.contains(c.uid);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => setState(() {
                          if (isSelected) {
                            _selected.remove(c.uid);
                          } else {
                            _selected.add(c.uid);
                          }
                        }),
                        activeColor: cs.primary,
                        checkColor: cs.onPrimary,
                        title: Text(c.displayName,
                            style: TextStyle(color: cs.onSurface)),
                        subtitle: Text(c.phone,
                            style: TextStyle(
                                color: cs.onSurface
                                    .withValues(alpha: 0.38))),
                        secondary: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHigh,
                          child: Text(
                            c.displayName.isNotEmpty
                                ? c.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${_selected.length} membre(s) sélectionné(s)',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.54),
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
