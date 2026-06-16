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
    final cs = Theme.of(context).colorScheme;
    final contacts = context.watch<ContactsProvider>().contacts;
    final myUid = context.read<AuthProvider>().user?.uid ?? '';

    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: cs.onSurface.withValues(alpha: 0.24)),
            const SizedBox(height: 16),
            Text('Aucun contact',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.38))),
            const SizedBox(height: 8),
            Text('Appuie sur + pour en ajouter un',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.24),
                    fontSize: 12)),
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
            backgroundColor: cs.surfaceContainerHigh,
            child: Text(
              c.displayName.isNotEmpty
                  ? c.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  color: cs.primary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(c.displayName,
              style: TextStyle(
                  color: cs.onSurface, fontWeight: FontWeight.w600)),
          subtitle: Text(c.phone,
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.38))),
          onTap: () async {
            final chat = context.read<ChatProvider>();
            final conv = await chat.openDirectChat(myUid, c.uid);
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
