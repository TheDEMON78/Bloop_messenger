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
    final myUid =
        context.read<AuthProvider>().user?.uid ?? '';
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
    final contacts =
        context.watch<ContactsProvider>().contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau groupe'),
        actions: [
          TextButton(
            onPressed: _creating ? null : _create,
            child: _creating
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00F5FF)))
                : const Text('Créer',
                    style: TextStyle(
                        color: Color(0xFF00F5FF),
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
              style:
                  const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nom du groupe',
                labelStyle:
                    TextStyle(color: Color(0xFF00F5FF)),
                enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF00F5FF))),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Color(0xFF00F5FF), width: 2)),
              ),
            ),
          ),
          const Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Sélectionne des membres',
                style: TextStyle(
                    color: Colors.white54, fontSize: 12)),
          ),
          Expanded(
            child: contacts.isEmpty
                ? const Center(
                    child: Text('Aucun contact',
                        style:
                            TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (_, i) {
                      final c = contacts[i];
                      final isSelected =
                          _selected.contains(c.uid);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => setState(() {
                          if (isSelected) {
                            _selected.remove(c.uid);
                          } else {
                            _selected.add(c.uid);
                          }
                        }),
                        activeColor:
                            const Color(0xFF00F5FF),
                        checkColor: Colors.black,
                        title: Text(c.displayName,
                            style: const TextStyle(
                                color: Colors.white)),
                        subtitle: Text(c.phone,
                            style: const TextStyle(
                                color: Colors.white38)),
                        secondary: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF1A1A2E),
                          child: Text(
                            c.displayName.isNotEmpty
                                ? c.displayName[0]
                                    .toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Color(0xFF00F5FF),
                                fontWeight:
                                    FontWeight.bold),
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
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
