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

import '../../domain/stick_data.dart';
import '../../domain/stick_models.dart';
import '../sticks_scope.dart';
import '../widgets.dart';

/// Give a task in plain words to one Stick. It goes as a message from the
/// owner (`api.sticks.send_message`); the Stick plans the steps itself.
class GiveTaskScreen extends StatefulWidget {
  final String? stickId;
  const GiveTaskScreen({super.key, this.stickId});

  @override
  State<GiveTaskScreen> createState() => _GiveTaskScreenState();
}

class _GiveTaskScreenState extends State<GiveTaskScreen> {
  final _text = TextEditingController();
  String? _picked;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.stickId;
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send(StickData data) async {
    setState(() => _busy = true);
    await data.sendMessage(to: _picked!, kind: MessageKind.ask, body: _text.text.trim());
    if (mounted) SticksScope.of(context).nav.back();
  }

  @override
  Widget build(BuildContext context) {
    final s = SticksScope.of(context);
    final p = StickPalette.of(context);
    return SticksFuture<List<Stick>>(
      future: s.data.sticks(),
      builder: (context, all) {
        final sticks = all;
        _picked ??= sticks.isEmpty ? null : sticks.first.id;
        final who = sticks.where((x) => x.id == _picked).firstOrNull;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const StickTop(title: 'Give a task', sub: 'Say it the way you would to a person', back: 'Team'),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (final st in sticks)
                GestureDetector(
                  onTap: () => setState(() => _picked = st.id),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: st.id == _picked ? st.accent : Colors.transparent, width: 2)),
                      child: StickRing(stick: st, size: 46),
                    ),
                    Text(st.name, style: sticksLabel(context, 11, color: st.id == _picked ? p.ink : p.soft)),
                  ]),
                ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: p.card, border: Border.all(color: p.ink, width: 2), borderRadius: BorderRadius.circular(18)),
                child: TextField(
                  controller: _text,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontSize: 15.5, height: 1.45),
                  decoration: const InputDecoration.collapsed(hintText: 'Call back everyone who asked for a quote this week…'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (who != null)
              Text('${who.name} plans the steps and asks you before anything leaves the company.',
                  style: TextStyle(color: p.soft, fontSize: 13)),
            const SizedBox(height: 10),
            SticksButton(
              who == null ? 'Give task' : 'Hand it to ${who.name}',
              onTap: (_busy || who == null || _text.text.trim().isEmpty) ? null : () => _send(s.data),
            ),
          ]),
        );
      },
    );
  }
}
