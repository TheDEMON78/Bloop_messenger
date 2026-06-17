import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/conversation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_tab == 0)
            IconButton(
              icon: const Icon(Icons.group_add),
              tooltip: 'Créer un groupe',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const CreateGroupScreen())),
            ),
          if (_tab == 1)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Ajouter un contact',
              onPressed: () => Navigator.push(context,
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
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline,
                color: cs.onSurface.withValues(alpha: 0.6)),
            selectedIcon: Icon(Icons.chat_bubble, color: cs.primary),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined,
                color: cs.onSurface.withValues(alpha: 0.6)),
            selectedIcon: Icon(Icons.contacts, color: cs.primary),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline,
                color: cs.onSurface.withValues(alpha: 0.6)),
            selectedIcon: Icon(Icons.person, color: cs.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _ConversationsTab extends StatefulWidget {
  const _ConversationsTab();

  @override
  State<_ConversationsTab> createState() => _ConversationsTabState();
}

class _ConversationsTabState extends State<_ConversationsTab> {
  DateTime? _lastRefresh;

  Future<void> _onRefresh() async {
    final now = DateTime.now();
    if (_lastRefresh != null &&
        now.difference(_lastRefresh!) < const Duration(minutes: 5)) {
      final remaining = const Duration(minutes: 5) -
          now.difference(_lastRefresh!);
      final mins = remaining.inMinutes;
      final secs = remaining.inSeconds % 60;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Actualisation disponible dans ${mins > 0 ? '${mins}m ' : ''}${secs}s'),
          duration: const Duration(seconds: 2),
        ));
      }
      return;
    }
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    context.read<ChatProvider>().listenConversations(uid);
    _lastRefresh = now;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final conversations = context.watch<ChatProvider>().conversations;
    final myUid = context.read<AuthProvider>().user?.uid ?? '';

    if (conversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: cs.primary,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64,
                      color: cs.onSurface.withValues(alpha: 0.24)),
                  const SizedBox(height: 16),
                  Text('Aucune conversation',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.38))),
                  const SizedBox(height: 8),
                  Text('Ajoute un contact pour commencer',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.24),
                          fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: cs.primary,
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (_, i) =>
            _ConversationTile(conv: conversations[i], myUid: myUid),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conv;
  final String myUid;

  const _ConversationTile({required this.conv, required this.myUid});

  String _resolveTitle(BuildContext context) {
    if (conv.isGroup) return conv.groupName ?? 'Groupe';
    final otherUid = conv.participants
        .firstWhere((p) => p != myUid, orElse: () => '');
    if (otherUid.isEmpty) return 'Chat';
    // 1. Check stored participant names
    final stored = conv.participantNames[otherUid];
    if (stored != null && stored.isNotEmpty) return stored;
    // 2. Check contacts list
    final contacts = context.read<ContactsProvider>().contacts;
    final contact =
        contacts.where((c) => c.uid == otherUid).firstOrNull;
    return contact?.displayName ?? 'Utilisateur';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = _resolveTitle(context);
    final unread = conv.unreadCount[myUid] ?? 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.surfaceContainerHigh,
        child: Icon(
          conv.isGroup ? Icons.group : Icons.person,
          color: cs.primary,
        ),
      ),
      title: Text(title,
          style: TextStyle(
              color: cs.onSurface, fontWeight: FontWeight.w600)),
      subtitle: Text(
        conv.lastMessage ?? '',
        style:
            TextStyle(color: cs.onSurface.withValues(alpha: 0.38)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: unread > 0
          ? CircleAvatar(
              radius: 10,
              backgroundColor: cs.primary,
              child: Text('$unread',
                  style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
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
