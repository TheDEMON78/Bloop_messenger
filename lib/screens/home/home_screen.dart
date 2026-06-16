import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/conversation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contacts_provider.dart';
import '../chat/chat_screen.dart';
import '../contacts/contacts_screen.dart';
import '../contacts/add_contact_screen.dart';
import '../groups/create_group_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<ChatProvider>().listenConversations(uid);
      context.read<ContactsProvider>().listenContacts(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Messages', 'Contacts', 'Profil'];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_tab],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_tab == 0)
            IconButton(
              icon: const Icon(Icons.group_add),
              tooltip: 'Créer un groupe',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateGroupScreen())),
            ),
          if (_tab == 1)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Ajouter un contact',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddContactScreen())),
            ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _ConversationsTab(),
          ContactsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _ConversationsTab extends StatelessWidget {
  const _ConversationsTab();

  @override
  Widget build(BuildContext context) {
    final conversations = context.watch<ChatProvider>().conversations;
    final myUid = context.read<AuthProvider>().user?.uid ?? '';

    if (conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Aucune conversation',
                style: TextStyle(color: Colors.white38)),
            SizedBox(height: 8),
            Text('Ajoute un contact pour commencer',
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (_, i) =>
          _ConversationTile(conv: conversations[i], myUid: myUid),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conv;
  final String myUid;

  const _ConversationTile({required this.conv, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final title = conv.isGroup
        ? (conv.groupName ?? 'Groupe')
        : conv.participants
            .firstWhere((p) => p != myUid, orElse: () => '');
    final unread = conv.unreadCount[myUid] ?? 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1A1A2E),
        child: Icon(
          conv.isGroup ? Icons.group : Icons.person,
          color: const Color(0xFF00F5FF),
        ),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(
        conv.lastMessage ?? '',
        style: const TextStyle(color: Colors.white38),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: unread > 0
          ? CircleAvatar(
              radius: 10,
              backgroundColor: const Color(0xFF00F5FF),
              child: Text(
                '$unread',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChatScreen(conversation: conv, myUid: myUid),
        ),
      ),
    );
  }
}
