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

/// Between Sticks: every message from one Stick to another, read-only for
/// the owner. A sensitive request waits here until the owner allows it; the
/// Stick that holds the data is the one that asks.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<(List<StickMessage>, List<Stick>)>(
      future: Future.wait([s.data.inbox('team'), s.data.sticks()])
          .then((v) => (v[0] as List<StickMessage>, v[1] as List<Stick>)),
      builder: (context, r) {
        final (messages, team) = r;
        return ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
          const StickTop(title: 'Between Sticks', sub: 'What your Sticks say to each other', back: 'Team'),
          const SizedBox(height: 4),
          Text('You can read everything. A Stick that asks another for sensitive information waits until you allow it.',
              style: TextStyle(color: p.soft, fontSize: 12.5, height: 1.35)),
          const SizedBox(height: 10),
          if (messages.isEmpty) Text('Your Sticks have not talked yet.', style: TextStyle(color: p.soft)),
          for (final m in messages)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: MessageBubble(m: m, team: team, onOpenAsk: s.nav.openAsk)),
        ]);
      },
    );
  }
}

/// One message with who sent it, who it is for, and what became of it.
class MessageBubble extends StatelessWidget {
  final StickMessage m;
  final List<Stick> team;
  final void Function(String stickId)? onOpenAsk;
  final Widget? footer;
  const MessageBubble({super.key, required this.m, required this.team, this.onOpenAsk, this.footer});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    final from = Party.of(m.fromId, team);
    final to = Party.of(m.toId, team);
    final waiting = m.status == MessageStatus.awaitingPermission;
    final tint = from.stick?.accent ?? p.ink;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PartyAvatar(from, size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Color.alphaBlend(tint.withValues(alpha: waiting ? .05 : .13), p.card),
              borderRadius: BorderRadius.circular(14),
              border: waiting ? Border.all(color: StickPalette.waiting, width: 1.5) : null,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${from.name} to ${to.name}  ·  ${shortDate(m.sentAt)}', style: sticksLabel(context, 11, color: p.soft)),
              const SizedBox(height: 2),
              Text(m.body, style: const TextStyle(fontSize: 13.5, height: 1.35)),
              if (m.attachments.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 5, runSpacing: 5, children: [for (final a in m.attachments) SticksChip('📎 ${a.label}')]),
              ],
              if (footer != null) footer!,
            ]),
          ),
        ),
      ]),
      if (m.status != MessageStatus.delivered)
        Padding(
          padding: const EdgeInsets.only(left: 40, top: 6),
          child: waiting
              ? Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: StickPalette.waiting.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Waiting for your permission', style: sticksLabel(context, 13)),
                    const SizedBox(height: 2),
                    Text('${to.name} has not handed anything over. Allow ${from.name} to ask?', style: TextStyle(color: p.ink2, fontSize: 12.5)),
                    if (onOpenAsk != null && m.toId != 'owner') ...[
                      const SizedBox(height: 8),
                      SticksButton('Review the request', onTap: () => onOpenAsk!(m.toId)),
                    ],
                  ]),
                )
              : Text(
                  m.status == MessageStatus.held ? "Held until ${to.name}'s next shift" : "You didn't allow this",
                  style: sticksLabel(context, 11.5, color: p.soft),
                ),
        ),
    ]);
  }
}
