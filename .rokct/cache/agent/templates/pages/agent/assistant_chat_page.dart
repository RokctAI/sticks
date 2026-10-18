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


import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:agent_sdk/agent_sdk.dart';
// The generated host router (app_router.gr.dart) names this type in the
// AssistantChatRoute args signature.
export 'package:agent_sdk/agent_sdk.dart' show AssistantService;
import 'package:${package}/presentation/theme/theme.dart';
import 'package:remixicon/remixicon.dart';

@RoutePage(name: 'AssistantChatRoute')
class AssistantChatPage extends StatefulWidget {
  final AssistantService assistantService;

  const AssistantChatPage({
    super.key,
    required this.assistantService,
  });

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  // Set when the assistant backend reports a failure. The banner shows only
  // a friendly, persona-named line in system voice — never a chat bubble
  // from the persona. The server's own reason (e.g. its "assistant not
  // configured" message) is admin detail: it goes to telemetry via
  // AssistantService and is never rendered to students.
  bool _assistantUnavailable = false;

  // The plan gate's own line ("Chat isn't included in your plan."), which
  // the server sends as a 403 and IS meant for students; null for every
  // other failure, which keeps the generic banner.
  String? _planGateMessage;

  // True from a send until its answer or its error arrives: the send button
  // is disabled and a progress line shows, so one question is in flight.
  bool _awaitingReply = false;

  String get _assistantName => widget.assistantService.displayName;

  String get _unavailableBannerText {
    final planGate = _planGateMessage?.trim() ?? '';
    if (planGate.isNotEmpty) return planGate;
    return _assistantName.trim().isEmpty
        ? "The assistant isn't available right now"
        : "$_assistantName isn't available right now";
  }

  StreamSubscription<ChatMessage>? _outgoingSub;
  StreamSubscription<AssistantChatError>? _errorsSub;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
    _outgoingSub = widget.assistantService.outgoingChat.stream.listen((message) {
      if (mounted) {
        setState(() {
          _messages.add(message);
          _awaitingReply = false;
        });
      }
    });
    _errorsSub = widget.assistantService.errors.listen((error) {
      if (mounted) {
        setState(() {
          _assistantUnavailable = true;
          _awaitingReply = false;
          _planGateMessage = error.statusCode == 403 ? error.message : null;
        });
      }
    });
  }

  /// The signed-in account's earlier conversation, shown above anything
  /// already said on this page. Local only: offline it loads the same, and
  /// a history that cannot be read simply shows nothing - never an error.
  Future<void> _loadHistory() async {
    final history = await widget.assistantService.loadHistory();
    if (!mounted || history.isEmpty) return;
    setState(() {
      final shown = {for (final m in _messages) m.id};
      _messages.insertAll(
        0,
        history.where((m) => !shown.contains(m.id)),
      );
    });
  }

  @override
  void dispose() {
    // Cancel this page's own listeners; the service and its controllers
    // outlive the page (they belong to the host).
    _outgoingSub?.cancel();
    _errorsSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_awaitingReply) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: 'Student',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(msg);
      _assistantUnavailable = false;
      _planGateMessage = null;
      _awaitingReply = true;
    });

    widget.assistantService.incomingChat.add(msg);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.mainBack,
      appBar: AppBar(
        backgroundColor: AppStyle.mainBack,
        title: Text(
          'Chat with $_assistantName',
          style: AppStyle.interNormal(size: 16),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAssistant = msg.sender == _assistantName;
                return Align(
                  alignment: isAssistant
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAssistant
                          ? AppStyle.primary.withOpacity(0.15)
                          : AppStyle.subCategory,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${msg.sender}: ${msg.text}',
                      style: AppStyle.interRegular(size: 14),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_awaitingReply)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: LinearProgressIndicator(),
            ),
          if (_assistantUnavailable)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppStyle.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _unavailableBannerText,
                style: AppStyle.interRegular(size: 13, color: AppStyle.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppStyle.interRegular(size: 14),
                    decoration: InputDecoration(
                      hintText: 'Ask $_assistantName...',
                      hintStyle: AppStyle.interRegular(
                        size: 14,
                        color: AppStyle.textHint,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Remix.send_plane_fill),
                  color: AppStyle.icons,
                  onPressed: _awaitingReply ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
