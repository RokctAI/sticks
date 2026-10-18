// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';

import '../../domain/stick_models.dart';
import '../sticks_scope.dart';
import '../widgets.dart';
import 'conversations_screen.dart';

/// The owner's inbox, and any Stick's inbox for oversight. In the owner's
/// own inbox a message can be answered, or handed back with an attachment;
/// another Stick's inbox is read-only.
class InboxScreen extends StatefulWidget {
  final String forWho;
  const InboxScreen({super.key, this.forWho = 'owner'});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late String _who = widget.forWho;
  String? _replying;
  final _text = TextEditingController();
  final _file = TextEditingController();
  bool _handBack = false;
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    _text.dispose();
    _file.dispose();
    super.dispose();
  }

  Future<void> _send(StickMessage m) async {
    final s = SticksScope.of(context);
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await s.data.sendMessage(
        to: m.fromId,
        kind: _handBack ? MessageKind.handoff : MessageKind.note,
        body: _text.text.trim(),
        replyTo: m.id,
        taskId: m.taskId,
        attachments: _handBack && _file.text.trim().isNotEmpty ? [MessageAttachment(_file.text.trim(), _file.text.trim())] : const [],
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _replying = null;
          _text.clear();
          _file.clear();
          _handBack = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<(List<StickMessage>, List<Stick>)>(
      future: Future.wait([s.data.inbox(_who), s.data.sticks()])
          .then((v) => (v[0] as List<StickMessage>, v[1] as List<Stick>)),
      builder: (context, r) {
        final (messages, team) = r;
        final mine = _who == 'owner';
        return ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
          StickTop(title: mine ? 'Inbox' : "${Party.of(_who, team).name}'s inbox", sub: mine ? 'Messages for you' : 'You are reading this, not answering it', back: 'Team'),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              Padding(padding: const EdgeInsets.only(right: 6), child: SticksChip('You', on: mine, onTap: () => setState(() => _who = 'owner'))),
              for (final st in team)
                Padding(padding: const EdgeInsets.only(right: 6), child: SticksChip(st.name, on: _who == st.id, onTap: () => setState(() => _who = st.id))),
            ]),
          ),
          const SizedBox(height: 12),
          if (messages.isEmpty) Text('Nothing here.', style: TextStyle(color: p.soft)),
          for (final m in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MessageBubble(
                m: m,
                team: team,
                footer: !mine
                    ? null
                    : _replying == m.id
                        ? _Composer(
                            text: _text,
                            file: _file,
                            handBack: _handBack,
                            busy: _busy,
                            failed: _failed,
                            onHandBack: (v) => setState(() => _handBack = v),
                            onSend: () => _send(m),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _replying = m.id),
                              child: Text('Reply', style: sticksLabel(context, 12.5)),
                            ),
                          ),
              ),
            ),
        ]);
      },
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController text, file;
  final bool handBack, busy, failed;
  final ValueChanged<bool> onHandBack;
  final VoidCallback onSend;
  const _Composer({
    required this.text,
    required this.file,
    required this.handBack,
    required this.busy,
    required this.failed,
    required this.onHandBack,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.rule), borderRadius: BorderRadius.circular(10)),
        child: TextField(controller: text, minLines: 1, maxLines: 4, decoration: const InputDecoration.collapsed(hintText: 'Your reply')),
      ),
      const SizedBox(height: 6),
      Wrap(spacing: 6, children: [
        SticksChip('Answer', on: !handBack, onTap: () => onHandBack(false)),
        SticksChip('Hand back with a file', on: handBack, onTap: () => onHandBack(true)),
      ]),
      if (handBack) ...[
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: p.paper, border: Border.all(color: p.rule), borderRadius: BorderRadius.circular(10)),
          child: TextField(controller: file, decoration: const InputDecoration.collapsed(hintText: 'File name, e.g. Statement Sep')),
        ),
      ],
      if (failed) Text("That didn't go through. Try again.", style: TextStyle(color: StickPalette.alert, fontSize: 12.5)),
      const SizedBox(height: 8),
      SticksButton('Send', onTap: busy ? null : onSend),
    ]);
  }
}
