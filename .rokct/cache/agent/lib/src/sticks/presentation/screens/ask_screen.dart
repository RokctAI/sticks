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
import '../stick_figure.dart';
import '../sticks_scope.dart';
import '../widgets.dart';

/// An ask only the owner can answer, drawn from the confirm the server
/// sends: a plain confirm, a permission to share sensitive data, or a draft
/// of something that leaves the company (email, call, payment, post).
/// Nothing goes out until the owner answers; the screen renders exactly the
/// options it is given and sends back the key.
class AskScreen extends StatefulWidget {
  final String stickId;
  const AskScreen({super.key, required this.stickId});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _note = TextEditingController();
  bool _busy = false;
  bool _editing = false;
  bool _failed = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _answer(StickConfirm c, ConfirmOption o) async {
    final s = SticksScope.of(context);
    if (o.key == 'edit' && !_editing) {
      setState(() => _editing = true);
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await s.data.answerConfirm(c.id, o.key, note: _note.text.trim().isEmpty ? null : _note.text.trim());
      if (mounted) s.nav.back();
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
    return SticksFuture<(StickConfirm?, List<Stick>)>(
      future: Future.wait([s.data.confirm(widget.stickId), s.data.sticks()])
          .then((v) => (v[0] as StickConfirm?, v[1] as List<Stick>)),
      builder: (context, r) {
        final (c, team) = r;
        final stick = team.where((x) => x.id == widget.stickId).firstOrNull;
        if (c == null || stick == null) {
          return Center(child: Text('Nothing to answer.', style: TextStyle(color: p.soft)));
        }
        final who = Party.of(c.requesterId ?? c.stickId, team).name;
        final title = switch (c.kind) {
          ConfirmKind.permission => 'Share sensitive data?',
          ConfirmKind.draft => 'Approve before it goes out',
          ConfirmKind.confirm => '${stick.name} asks',
        };
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Align(alignment: Alignment.centerLeft, child: StickTop(title: title, sub: c.deadline == null ? null : 'by ${shortDate(c.deadline)}', back: 'Asks')),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CoveredSheet(
              stick: stick,
              mood: StickMood.worried,
              child: ListView(children: [
                Text(c.question, style: sticksHead(context, 17)),
                const SizedBox(height: 10),
                if (c.kind == ConfirmKind.permission)
                  _Fields(rows: [
                    ('Asked by', who),
                    ('Held by', stick.name),
                    ('Data', c.dataLabel ?? ''),
                  ]),
                if (c.kind == ConfirmKind.draft && c.draft != null) _DraftView(d: c.draft!),
                if (_editing) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: p.ink, width: 2), borderRadius: BorderRadius.circular(14)),
                    child: TextField(
                      controller: _note,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration.collapsed(hintText: 'What should change?'),
                    ),
                  ),
                ],
                if (_failed)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text("That didn't go through. Try again.", style: TextStyle(color: StickPalette.alert, fontSize: 13)),
                  ),
                const SizedBox(height: 14),
                for (final o in c.options) ...[
                  SticksButton(
                    o.key == 'edit' && _editing ? 'Send my changes' : o.label,
                    filled: o.primary,
                    onTap: _busy ? null : () => _answer(c, o),
                  ),
                  const SizedBox(height: 8),
                ],
              ]),
            ),
          ),
        ]);
      },
    );
  }
}

class _Fields extends StatelessWidget {
  final List<(String, String)> rows;
  const _Fields({required this.rows});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    return Container(
      decoration: BoxDecoration(border: Border.all(color: p.rule), borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: p.rule))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 80, child: Text(rows[i].$1, style: TextStyle(color: p.soft, fontSize: 13.5))),
              Expanded(child: Text(rows[i].$2, style: sticksLabel(context, 13.5))),
            ]),
          ),
      ]),
    );
  }
}

/// What a Stick drafted. Email shows to, subject and body; a call shows the
/// number and the purpose; every channel shows what it is given.
class _DraftView extends StatelessWidget {
  final StickDraft d;
  const _DraftView({required this.d});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    final isCall = d.channel == 'call';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Fields(rows: [
        ('Channel', d.channel[0].toUpperCase() + d.channel.substring(1)),
        (isCall ? 'Number' : 'To', d.to.join(', ')),
        if (d.subject.isNotEmpty) (isCall ? 'Purpose' : 'Subject', d.subject),
        if (d.attachments.isNotEmpty) ('Attached', d.attachments.join(', ')),
      ]),
      if (d.body.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.rule)),
          child: Text(d.body, style: const TextStyle(fontSize: 13.5, height: 1.4)),
        ),
      ],
    ]);
  }
}

/// The Asks tab: every Stick that has a confirm waiting on the owner.
class AsksTab extends StatelessWidget {
  const AsksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<List<(Stick, StickConfirm)>>(
      future: () async {
        final out = <(Stick, StickConfirm)>[];
        for (final st in await s.data.sticks()) {
          if (st.openConfirms == 0) continue;
          final c = await s.data.confirm(st.id);
          if (c != null) out.add((st, c));
        }
        return out;
      }(),
      builder: (context, asks) {
        if (asks.isEmpty) return const EmptyState(title: 'Nothing to answer', line: 'Your Sticks are not waiting on you.');
        return ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
          StickTop(title: 'Asks', sub: '${asks.length} waiting on you'),
          const SizedBox(height: 10),
          for (final (st, c) in asks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => s.nav.openAsk(st.id),
                behavior: HitTestBehavior.opaque,
                child: SticksCard(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                  child: Row(children: [
                    StickRing(stick: st, size: 44),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.question, maxLines: 2, overflow: TextOverflow.ellipsis, style: sticksLabel(context, 13.5)),
                      Text(switch (c.kind) { ConfirmKind.permission => 'Permission', ConfirmKind.draft => 'Draft', ConfirmKind.confirm => 'Ask' },
                          style: TextStyle(color: p.soft, fontSize: 12)),
                    ])),
                    Text('›', style: TextStyle(color: p.soft, fontSize: 22)),
                  ]),
                ),
              ),
            ),
        ]);
      },
    );
  }
}

/// A calm empty page with a full Stick on it.
class EmptyState extends StatelessWidget {
  final String title;
  final String line;
  final VoidCallback? action;
  final String? actionLabel;
  const EmptyState({super.key, required this.title, required this.line, this.action, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<List<Stick>>(
      future: s.data.sticks(),
      builder: (context, sticks) {
        final host = sticks.where((x) => x.status == StickStatus.working).firstOrNull ?? sticks.firstOrNull;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(children: [
            if (host != null) SizedBox(width: 150, child: StickFigure(look: host.look, mood: StickMood.happy, dark: p.dark)),
            Text(title, style: sticksHead(context, 21)),
            const SizedBox(height: 4),
            Text(line, textAlign: TextAlign.center, style: TextStyle(color: p.soft)),
            const Spacer(),
            SticksButton(actionLabel ?? 'Give a task', onTap: action ?? () => s.nav.openGiveTask()),
          ]),
        );
      },
    );
  }
}
