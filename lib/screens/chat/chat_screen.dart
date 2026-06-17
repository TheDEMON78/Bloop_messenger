import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/background_message_service.dart';
import '../../services/block_service.dart';
import '../../services/firestore_service.dart';
import '../groups/group_settings_screen.dart';

String _formatLastSeen(DateTime lastSeen) {
  final diff = DateTime.now().difference(lastSeen);
  if (diff.inMinutes < 1) return 'Vu à l\'instant';
  if (diff.inHours < 1) return 'Vu il y a ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'Vu à ${DateFormat('HH:mm').format(lastSeen)}';
  return 'Vu le ${DateFormat('dd/MM').format(lastSeen)}';
}

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  final String myUid;

  const ChatScreen(
      {super.key, required this.conversation, required this.myUid});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _blockService = BlockService();
  final _db = FirestoreService();
  Timer? _typingTimer;

  String get _otherUid => widget.conversation.isGroup
      ? ''
      : widget.conversation.participants
          .firstWhere((p) => p != widget.myUid, orElse: () => '');

  @override
  void initState() {
    super.initState();
    context.read<ChatProvider>().listenMessages(widget.conversation.id);
    SharedPreferences.getInstance()
        .then((p) => p.setString(kPrefKeyOpenConv, widget.conversation.id));
    _msgCtrl.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    _stopTyping();
    _typingTimer?.cancel();
    SharedPreferences.getInstance()
        .then((p) => p.remove(kPrefKeyOpenConv));
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onTypingChanged() {
    if (_msgCtrl.text.isEmpty) {
      _stopTyping();
      return;
    }
    _db.setTyping(widget.conversation.id, widget.myUid, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(
      const Duration(seconds: 3),
      _stopTyping,
    );
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    _db.setTyping(widget.conversation.id, widget.myUid, false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _stopTyping();
    _msgCtrl.clear();
    await context.read<ChatProvider>().sendMessage(
          conversationId: widget.conversation.id,
          senderId: widget.myUid,
          content: text,
        );
    _scrollToBottom();
  }

  Future<void> _showBlockDialog(bool isCurrentlyBlocked) async {
    final cs = Theme.of(context).colorScheme;
    final action = isCurrentlyBlocked ? 'Débloquer' : 'Bloquer';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action, style: TextStyle(color: cs.onSurface)),
        content: Text(
          isCurrentlyBlocked
              ? 'Débloquer cet utilisateur ?'
              : 'Bloquer cet utilisateur ? Il ne pourra plus vous envoyer de messages.',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style:
                    TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action,
                style: TextStyle(
                    color:
                        isCurrentlyBlocked ? cs.primary : Colors.redAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      if (isCurrentlyBlocked) {
        await _blockService.unblockUser(widget.myUid, _otherUid);
      } else {
        await _blockService.blockUser(widget.myUid, _otherUid);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> _showReportDialog() async {
    final cs = Theme.of(context).colorScheme;
    String? selectedReason;
    final reasons = [
      'Spam',
      'Harcèlement',
      'Contenu inapproprié',
      'Usurpation d\'identité',
      'Autre',
    ];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Signaler', style: TextStyle(color: cs.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Raison du signalement :',
                  style:
                      TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 12),
              ...reasons.map((r) => RadioListTile<String>(
                    value: r,
                    groupValue: selectedReason,
                    onChanged: (v) => setS(() => selectedReason = v),
                    title: Text(r, style: TextStyle(color: cs.onSurface)),
                    activeColor: cs.primary,
                    dense: true,
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Annuler',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.54))),
            ),
            TextButton(
              onPressed:
                  selectedReason == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Envoyer',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true && selectedReason != null && mounted) {
      await _blockService.reportUser(
        reporterUid: widget.myUid,
        targetUid: _otherUid,
        reason: selectedReason!,
        conversationId: widget.conversation.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signalement envoyé. Merci.')));
      }
    }
  }

  Widget _buildTitle(ColorScheme cs) {
    if (widget.conversation.isGroup) {
      return StreamBuilder<String?>(
        stream: FirestoreService().groupNameStream(widget.conversation.id),
        builder: (_, snap) {
          final name =
              snap.data ?? widget.conversation.groupName ?? 'Groupe';
          return Text(name,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis);
        },
      );
    }
    final stored = widget.conversation.participantNames[_otherUid];
    return StreamBuilder<UserModel?>(
      stream: FirestoreService().userStream(_otherUid),
      builder: (_, snap) {
        final user = snap.data;
        final name = user?.displayName ?? stored ?? '...';
        final presenceText = user == null
            ? null
            : user.isOnline
                ? 'En ligne'
                : _formatLastSeen(user.lastSeen);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            if (presenceText != null)
              Text(presenceText,
                  style: TextStyle(
                      fontSize: 11,
                      color: user?.isOnline == true
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.5))),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator(ColorScheme cs) {
    return StreamBuilder<List<String>>(
      stream: _db.typingStream(widget.conversation.id, widget.myUid),
      builder: (_, snap) {
        final typingUids = snap.data ?? [];
        if (typingUids.isEmpty) return const SizedBox.shrink();
        String text;
        if (widget.conversation.isGroup) {
          final names = typingUids
              .map((uid) =>
                  widget.conversation.participantNames[uid] ?? '...')
              .toList();
          text = typingUids.length == 1
              ? '${names.first} est en train d\'écrire...'
              : 'Plusieurs personnes écrivent...';
        } else {
          text = 'En train d\'écrire...';
        }
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final messages = context.watch<ChatProvider>().messages;
    final isDirectChat =
        !widget.conversation.isGroup && _otherUid.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.surfaceContainerHigh,
              child: Icon(
                widget.conversation.isGroup ? Icons.group : Icons.person,
                color: cs.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _buildTitle(cs)),
          ],
        ),
        actions: [
          if (widget.conversation.isGroup &&
              widget.conversation.creatorUid == widget.myUid)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Paramètres du groupe',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupSettingsScreen(
                    conversation: widget.conversation,
                    myUid: widget.myUid,
                  ),
                ),
              ),
            ),
          if (isDirectChat)
            StreamBuilder<bool>(
              stream: _blockService.isBlockedStream(widget.myUid, _otherUid),
              builder: (_, snap) {
                final isBlocked = snap.data ?? false;
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  color: cs.surfaceContainerHigh,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'block',
                      child: Row(children: [
                        Icon(isBlocked ? Icons.lock_open : Icons.block,
                            color:
                                isBlocked ? cs.primary : Colors.redAccent,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(isBlocked ? 'Débloquer' : 'Bloquer',
                            style: TextStyle(
                                color: isBlocked
                                    ? cs.primary
                                    : Colors.redAccent)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Row(children: [
                        const Icon(Icons.flag_outlined,
                            color: Colors.orangeAccent, size: 18),
                        const SizedBox(width: 8),
                        Text('Signaler',
                            style: TextStyle(color: cs.onSurface)),
                      ]),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'block') _showBlockDialog(isBlocked);
                    if (v == 'report') _showReportDialog();
                  },
                );
              },
            ),
        ],
      ),
      body: isDirectChat
          ? StreamBuilder<bool>(
              stream: _blockService.isBlockedStream(widget.myUid, _otherUid),
              builder: (_, snap) {
                final isBlocked = snap.data ?? false;
                return Column(
                  children: [
                    if (isBlocked)
                      Container(
                        width: double.infinity,
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.block,
                                color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Utilisateur bloqué — il ne peut plus vous écrire.',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showBlockDialog(true),
                              child: Text('Débloquer',
                                  style: TextStyle(
                                      color: cs.primary, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                        child: _MessagesList(
                            messages: messages,
                            myUid: widget.myUid,
                            conversationId: widget.conversation.id,
                            scrollCtrl: _scrollCtrl)),
                    if (!isBlocked) ...[
                      _buildTypingIndicator(cs),
                      _InputBar(controller: _msgCtrl, onSend: _send),
                    ],
                  ],
                );
              },
            )
          : Column(
              children: [
                Expanded(
                    child: _MessagesList(
                        messages: messages,
                        myUid: widget.myUid,
                        conversationId: widget.conversation.id,
                        scrollCtrl: _scrollCtrl)),
                _buildTypingIndicator(cs),
                _InputBar(controller: _msgCtrl, onSend: _send),
              ],
            ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  final List<MessageModel> messages;
  final String myUid;
  final String conversationId;
  final ScrollController scrollCtrl;

  const _MessagesList({
    required this.messages,
    required this.myUid,
    required this.conversationId,
    required this.scrollCtrl,
  });

  void _showOptions(BuildContext context, MessageModel msg) {
    final cs = Theme.of(context).colorScheme;
    final chat = context.read<ChatProvider>();
    final isMe = msg.senderId == myUid;
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: emojis
                    .map((e) => GestureDetector(
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            chat.toggleReaction(
                                conversationId, msg.id, myUid, e);
                          },
                          child:
                              Text(e, style: const TextStyle(fontSize: 28)),
                        ))
                    .toList(),
              ),
            ),
            if (isMe && !msg.isDeleted) ...[
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
              ListTile(
                leading: Icon(Icons.edit, color: cs.primary),
                title:
                    Text('Modifier', style: TextStyle(color: cs.onSurface)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showEditDialog(context, msg, chat);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Supprimer',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  chat.deleteMessage(conversationId, msg.id);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, MessageModel msg, ChatProvider chat) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text('Modifier le message',
            style: TextStyle(color: cs.onSurface)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: cs.onSurface),
          maxLines: null,
          decoration: InputDecoration(
            filled: true,
            fillColor: cs.surfaceContainer,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text('Annuler',
                style:
                    TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
          ),
          TextButton(
            onPressed: () {
              final newContent = ctrl.text.trim();
              if (newContent.isNotEmpty && newContent != msg.content) {
                chat.editMessage(conversationId, msg.id, newContent);
              }
              Navigator.pop(dlgCtx);
            },
            child: Text('Sauvegarder',
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chatProvider = context.read<ChatProvider>();

    if (messages.isEmpty) {
      return Center(
          child: Text('Dis bonjour 👋',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.38))));
    }
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final msg = messages[i];
        final isMe = msg.senderId == myUid;
        return _MessageBubble(
          message: msg,
          isMe: isMe,
          myUid: myUid,
          onLongPress:
              !msg.isDeleted ? () => _showOptions(ctx, msg) : null,
          onReactionToggle: (emoji) => chatProvider.toggleReaction(
              conversationId, msg.id, myUid, emoji),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String myUid;
  final VoidCallback? onLongPress;
  final void Function(String emoji)? onReactionToggle;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.myUid,
    this.onLongPress,
    this.onReactionToggle,
  });

  Widget _buildReactions(ColorScheme cs) {
    if (message.reactions.isEmpty) return const SizedBox.shrink();
    final counts = <String, int>{};
    final myReaction = message.reactions[myUid];
    for (final e in message.reactions.values) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: counts.entries.map((e) {
          final isMyReaction = myReaction == e.key;
          return GestureDetector(
            onTap: () => onReactionToggle?.call(e.key),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isMyReaction
                    ? cs.primary.withValues(alpha: 0.2)
                    : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMyReaction
                      ? cs.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Text('${e.key} ${e.value}',
                  style: const TextStyle(fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDeleted = message.isDeleted;
    final isEdited = !isDeleted && message.editedAt != null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDeleted
                    ? (isMe
                        ? cs.primary.withValues(alpha: 0.35)
                        : cs.surfaceContainer.withValues(alpha: 0.5))
                    : (isMe ? cs.primary : cs.surfaceContainer),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isDeleted
                          ? (isMe
                              ? cs.onPrimary.withValues(alpha: 0.5)
                              : cs.onSurface.withValues(alpha: 0.4))
                          : (isMe ? cs.onPrimary : cs.onSurface),
                      fontSize: 15,
                      fontStyle: isDeleted
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEdited)
                        Text(
                          'modifié · ',
                          style: TextStyle(
                            color: isMe
                                ? cs.onPrimary.withValues(alpha: 0.5)
                                : cs.onSurface.withValues(alpha: 0.38),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          color: isMe
                              ? cs.onPrimary.withValues(alpha: 0.6)
                              : cs.onSurface.withValues(alpha: 0.38),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildReactions(cs),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: cs.onSurface),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.38)),
                filled: true,
                fillColor: cs.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: cs.primary,
              child: Icon(Icons.send, color: cs.onPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
