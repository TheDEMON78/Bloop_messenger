import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/conversation_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/firestore_service.dart';

class GroupSettingsScreen extends StatefulWidget {
  final ConversationModel conversation;
  final String myUid;

  const GroupSettingsScreen(
      {super.key, required this.conversation, required this.myUid});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  bool _leaving = false;

  bool get _isCreator => widget.conversation.creatorUid == widget.myUid;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.conversation.groupName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;
    setState(() => _saving = true);
    await context.read<ChatProvider>().updateGroup(
          conversationId: widget.conversation.id,
          newGroupName: newName,
        );
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nom du groupe mis à jour')));
    }
  }

  Future<void> _removeMember(String uid) async {
    final cs = Theme.of(context).colorScheme;
    final name = widget.conversation.participantNames[uid] ?? uid;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Retirer $name ?',
            style: TextStyle(color: cs.onSurface)),
        content: Text('Ce membre ne pourra plus voir les messages du groupe.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style:
                    TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<ChatProvider>().updateGroup(
            conversationId: widget.conversation.id,
            removeUids: [uid],
          );
    }
  }

  Future<void> _showAddMemberDialog() async {
    final cs = Theme.of(context).colorScheme;
    final phoneCtrl = TextEditingController();
    UserModel? found;
    String? notFound;
    bool searching = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title:
              Text('Ajouter un membre', style: TextStyle(color: cs.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: cs.onSurface),
                      decoration: const InputDecoration(
                          hintText: '+33612345678'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: searching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.search, color: cs.primary),
                    onPressed: searching
                        ? null
                        : () async {
                            setS(() {
                              searching = true;
                              found = null;
                              notFound = null;
                            });
                            final u = await FirestoreService()
                                .getUserByPhone(phoneCtrl.text.trim());
                            setS(() {
                              searching = false;
                              if (u == null) {
                                notFound = 'Aucun utilisateur trouvé';
                              } else if (widget.conversation.participants
                                  .contains(u.uid)) {
                                notFound = 'Déjà membre du groupe';
                              } else {
                                found = u;
                              }
                            });
                          },
                  ),
                ],
              ),
              if (notFound != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(notFound!,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
              if (found != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: cs.surfaceContainerHigh,
                    child: Text(found!.displayName[0].toUpperCase(),
                        style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(found!.displayName,
                      style: TextStyle(color: cs.onSurface)),
                  subtitle: Text(found!.phone,
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.38))),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.54))),
            ),
            if (found != null)
              TextButton(
                onPressed: () async {
                  final user = found!;
                  Navigator.pop(ctx);
                  await context.read<ChatProvider>().updateGroup(
                        conversationId: widget.conversation.id,
                        addUids: [user.uid],
                        addNames: {user.uid: user.displayName},
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('${user.displayName} ajouté au groupe')));
                  }
                },
                child: Text('Ajouter',
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final conv = widget.conversation;
    final members = conv.participants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres du groupe'),
        actions: [
          if (_isCreator)
            _saving
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : TextButton(
                    onPressed: _save,
                    child: Text('Sauvegarder',
                        style: TextStyle(color: cs.primary))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Group name
          Text('Nom du groupe',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            enabled: _isCreator,
            style: TextStyle(color: cs.onSurface),
            decoration: InputDecoration(
              filled: true,
              fillColor: cs.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _isCreator
                  ? Icon(Icons.edit, color: cs.primary, size: 18)
                  : null,
            ),
          ),
          const SizedBox(height: 24),

          // Members section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Membres (${members.length})',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              if (_isCreator)
                TextButton.icon(
                  onPressed: _showAddMemberDialog,
                  icon: Icon(Icons.person_add, color: cs.primary, size: 18),
                  label: Text('Ajouter', style: TextStyle(color: cs.primary)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...members.map((uid) {
            final name = conv.participantNames[uid] ?? uid;
            final isCreatorMember = uid == conv.creatorUid;
            final isMe = uid == widget.myUid;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: CircleAvatar(
                backgroundColor: cs.surfaceContainerHigh,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: cs.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                isMe ? '$name (vous)' : name,
                style: TextStyle(color: cs.onSurface),
              ),
              subtitle: isCreatorMember
                  ? Text('Créateur',
                      style: TextStyle(
                          color: cs.primary.withValues(alpha: 0.8),
                          fontSize: 12))
                  : null,
              trailing: _isCreator && !isCreatorMember && !isMe
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.redAccent),
                      onPressed: () => _removeMember(uid),
                    )
                  : null,
            );
          }),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          // Leave / Delete group
          if (!_isCreator)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _leaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.orangeAccent))
                  : const Icon(Icons.exit_to_app,
                      color: Colors.orangeAccent),
              title: const Text('Quitter le groupe',
                  style: TextStyle(color: Colors.orangeAccent)),
              onTap: _leaving ? null : _leaveGroup,
            ),
          if (_isCreator)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _leaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.redAccent))
                  : const Icon(Icons.delete_forever,
                      color: Colors.redAccent),
              title: const Text('Supprimer le groupe',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: _leaving ? null : _deleteGroup,
            ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Quitter le groupe ?',
            style: TextStyle(color: cs.onSurface)),
        content: Text(
            'Tu ne pourras plus voir les messages de ce groupe.',
            style:
                TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.54))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter',
                style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _leaving = true);
    final myName = context.read<AuthProvider>().user?.displayName ?? '';
    await context
        .read<ChatProvider>()
        .leaveGroup(widget.conversation.id, widget.myUid, myName);
    if (mounted) {
      // Pop settings screen + chat screen back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _deleteGroup() async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer le groupe ?',
            style: TextStyle(color: cs.onSurface)),
        content: Text(
            'Tous les messages seront supprimés définitivement pour tous les membres.',
            style:
                TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.54))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _leaving = true);
    await context
        .read<ChatProvider>()
        .deleteGroup(widget.conversation.id);
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
