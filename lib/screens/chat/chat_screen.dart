import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/block_service.dart';

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

  String get _otherUid => widget.conversation.isGroup
      ? ''
      : widget.conversation.participants
          .firstWhere((p) => p != widget.myUid, orElse: () => '');

  @override
  void initState() {
    super.initState();
    context.read<ChatProvider>().listenMessages(widget.conversation.id);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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
    _msgCtrl.clear();
    await context.read<ChatProvider>().sendMessage(
          conversationId: widget.conversation.id,
          senderId: widget.myUid,
          content: text,
        );
    _scrollToBottom();
  }

  Future<void> _showBlockDialog(bool isCurrentlyBlocked) async {
    final action = isCurrentlyBlocked ? 'Débloquer' : 'Bloquer';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(action,
            style: const TextStyle(color: Colors.white)),
        content: Text(
          isCurrentlyBlocked
              ? 'Débloquer cet utilisateur ?'
              : 'Bloquer cet utilisateur ? Il ne pourra plus vous envoyer de messages.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action,
                style: TextStyle(
                    color: isCurrentlyBlocked
                        ? const Color(0xFF00F5FF)
                        : Colors.redAccent,
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
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Signaler',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Raison du signalement :',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ...reasons.map((r) => RadioListTile<String>(
                    value: r,
                    groupValue: selectedReason,
                    onChanged: (v) => setS(() => selectedReason = v),
                    title: Text(r,
                        style: const TextStyle(color: Colors.white)),
                    activeColor: const Color(0xFF00F5FF),
                    dense: true,
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(ctx, true),
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
          const SnackBar(
            content: Text('Signalement envoyé. Merci.'),
            backgroundColor: Color(0xFF1A1A2E),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.conversation.isGroup
        ? (widget.conversation.groupName ?? 'Groupe')
        : widget.conversation.participants
            .firstWhere((p) => p != widget.myUid, orElse: () => 'Chat');

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
              backgroundColor: const Color(0xFF1A1A2E),
              child: Icon(
                widget.conversation.isGroup ? Icons.group : Icons.person,
                color: const Color(0xFF00F5FF),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (isDirectChat)
            StreamBuilder<bool>(
              stream: _blockService.isBlockedStream(widget.myUid, _otherUid),
              builder: (_, snap) {
                final isBlocked = snap.data ?? false;
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  color: const Color(0xFF1A1A2E),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(
                            isBlocked
                                ? Icons.lock_open
                                : Icons.block,
                            color: isBlocked
                                ? const Color(0xFF00F5FF)
                                : Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isBlocked ? 'Débloquer' : 'Bloquer',
                            style: TextStyle(
                                color: isBlocked
                                    ? const Color(0xFF00F5FF)
                                    : Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined,
                              color: Colors.orangeAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Signaler',
                              style:
                                  TextStyle(color: Colors.orangeAccent)),
                        ],
                      ),
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
              stream:
                  _blockService.isBlockedStream(widget.myUid, _otherUid),
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
                                    color: Colors.redAccent,
                                    fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showBlockDialog(true),
                              child: const Text('Débloquer',
                                  style: TextStyle(
                                      color: Color(0xFF00F5FF),
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    Expanded(child: _MessagesList(messages: messages, myUid: widget.myUid, scrollCtrl: _scrollCtrl)),
                    if (!isBlocked)
                      _InputBar(controller: _msgCtrl, onSend: _send),
                  ],
                );
              },
            )
          : Column(
              children: [
                Expanded(child: _MessagesList(messages: messages, myUid: widget.myUid, scrollCtrl: _scrollCtrl)),
                _InputBar(controller: _msgCtrl, onSend: _send),
              ],
            ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  final List<MessageModel> messages;
  final String myUid;
  final ScrollController scrollCtrl;

  const _MessagesList({
    required this.messages,
    required this.myUid,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
          child: Text('Dis bonjour 👋',
              style: TextStyle(color: Colors.white38)));
    }
    return ListView.builder(
      controller: scrollCtrl,
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        return _MessageBubble(
            message: msg, isMe: msg.senderId == myUid);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF00B8CC)
              : const Color(0xFF1E1E2E),
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
                  color: isMe ? Colors.black : Colors.white,
                  fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.black54 : Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
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
    return Container(
      color: const Color(0xFF0D0D16),
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle:
                    const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E1E2E),
                border: OutlineInputBorder(
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
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF00F5FF),
              child: Icon(Icons.send, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
