import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contacts_provider.dart';
import '../chat/chat_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactsProvider>().contacts;
    final myUid = context.read<AuthProvider>().user?.uid ?? '';

    if (contacts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Aucun contact',
                style: TextStyle(color: Colors.white38)),
            SizedBox(height: 8),
            Text('Appuie sur + pour en ajouter un',
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (_, i) {
        final c = contacts[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF1A1A2E),
            child: Text(
              c.displayName.isNotEmpty
                  ? c.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Color(0xFF00F5FF),
                  fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(c.displayName,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          subtitle: Text(c.phone,
              style: const TextStyle(color: Colors.white38)),
          onTap: () async {
            final chat = context.read<ChatProvider>();
            final conv =
                await chat.openDirectChat(myUid, c.uid);
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ChatScreen(conversation: conv, myUid: myUid),
              ),
            );
          },
        );
      },
    );
  }
}
