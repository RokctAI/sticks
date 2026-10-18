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

import '../../domain/stick_looks.dart';
import '../../domain/stick_models.dart';
import '../stick_figure.dart';
import '../sticks_scope.dart';
import '../widgets.dart';

/// Setup for a new Stick. With [animated] it opens as the first-run intro: a
/// beam of white light in a dark room, a naked Stick climbs out, the room
/// lights up, the camera slides left and the options open on the right. The
/// clothes and item come on by themselves once a gender and a role are
/// picked, chosen so no two Sticks on the team look alike.
class SetupScreen extends StatefulWidget {
  final String? role;
  final bool animated;
  const SetupScreen({super.key, this.role, this.animated = false});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _name = TextEditingController();
  StickGender? _gender;
  String? _role;
  List<Stick> _team = const [];
  List<RoleOption> _roles = const [];
  bool _failed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _role = widget.role;
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
    _name.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = SticksScope.of(context).data;
    data.sticks().then((t) {
      if (mounted) setState(() => _team = t);
    });
    data.roles().then((r) {
      if (mounted) setState(() => _roles = r);
    });
    if (!_c.isAnimating && _c.value == 0) {
      if (widget.animated && !MediaQuery.of(context).disableAnimations) {
        _c.forward();
      } else {
        _c.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _name.dispose();
    super.dispose();
  }

  RoleOption? get _roleOption => _roles.where((r) => r.key == _role).firstOrNull;

  /// The look the clothes step shows once a gender and a role are chosen.
  StickLook? get _preview {
    final r = _roleOption;
    if (_gender == null || r == null) return null;
    return StickLooks.assign(
      gender: _gender!,
      roleKey: r.key,
      roleLabel: r.label,
      team: [for (final t in _team) t.look],
      teamRoles: [for (final t in _team) t.role],
    );
  }

  double _seg(double a, double b) => ((_c.value - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    final look = _preview ?? const StickLook.naked();
    final tint = _preview == null ? const Color(0xFFC9C5BB) : look.clothes;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final rise = Curves.easeOutCubic.transform(_seg(.18, .55));
        final lit = Curves.easeInOut.transform(_seg(.55, .75));
        final slide = Curves.easeInOutCubic.transform(_seg(.75, 1));
        return LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          final figW = Tween<double>(begin: w * .46, end: w * .46).transform(slide);
          final figH = figW * 1.4;
          final leftCol = w * .36;
          final cx = Tween<double>(begin: w / 2, end: leftCol / 2).transform(slide);
          final floor = Tween<double>(begin: h * .76, end: h - 78).transform(slide);
          final bg = Color.lerp(const Color(0xFF070707), Color.alphaBlend(tint.withValues(alpha: .18), p.paper), lit)!;
          return Stack(children: [
            Positioned.fill(child: ColoredBox(color: bg)),
            if (lit < 1)
              Positioned.fill(
                child: Opacity(
                  opacity: (1 - lit) * Curves.easeIn.transform(_seg(0, .18)),
                  child: CustomPaint(painter: _BeamPainter(floor: floor)),
                ),
              ),
            Positioned(
              left: cx - figW / 2,
              top: floor - figH + (1 - rise) * h * .5,
              width: figW,
              child: Opacity(
                opacity: rise,
                child: StickFigure(look: look, mood: lit < 1 ? StickMood.neutral : StickMood.happy, dark: p.dark || lit < 1),
              ),
            ),
            if (slide > 0)
              Positioned(
                left: 0, width: leftCol, bottom: 54,
                child: Opacity(
                  opacity: slide,
                  child: Center(child: Text(_name.text.trim(), style: sticksHead(context, 15))),
                ),
              ),
            if (slide > 0)
              Positioned(
                left: leftCol + (1 - slide) * (w - leftCol), right: 0, top: 0, bottom: 0,
                child: Opacity(opacity: slide, child: _panel(context, p, _preview)),
              ),
            if (_c.value < .75)
              Positioned(
                left: 0, right: 0, bottom: 28,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _c.value = 1,
                    child: const Text('Skip', style: TextStyle(color: Color(0xFFB8B4AA), fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ]);
        });
      },
    );
  }

  Widget _panel(BuildContext context, StickPalette p, StickLook? preview) {
    final s = SticksScope.of(context);
    final roles = _roles;
    final ready = preview != null && _name.text.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: s.nav.back,
          behavior: HitTestBehavior.opaque,
          child: Text('‹ Team', style: sticksLabel(context, 12.5, color: p.soft)),
        ),
        Text('New Stick', style: sticksHead(context, 19)),
        const SticksSectionLabel('Name'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(color: p.card, border: Border.all(color: p.rule), borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            style: sticksLabel(context, 14),
            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Lindiwe'),
          ),
        ),
        const SticksSectionLabel('Gender'),
        Wrap(spacing: 5, runSpacing: 5, children: [
          SticksChip('Woman', on: _gender == StickGender.woman, onTap: () => setState(() => _gender = StickGender.woman)),
          SticksChip('Man', on: _gender == StickGender.man, onTap: () => setState(() => _gender = StickGender.man)),
        ]),
        const SticksSectionLabel('Role'),
        Wrap(spacing: 5, runSpacing: 5, children: [
          for (final r in roles) SticksChip(r.label, on: _role == r.key, onTap: () => setState(() => _role = r.key)),
        ]),
        const SizedBox(height: 8),
        Text(
          preview == null
              ? 'Pick a gender and a role and the clothes come on their own.'
              : StickLooks.why(
                  gender: _gender!,
                  roleLabel: _roleOption!.label,
                  look: preview,
                  team: [for (final t in _team) t.look],
                  teamNames: [for (final t in _team) t.name],
                  teamRoles: [for (final t in _team) t.role],
                ),
          style: TextStyle(fontSize: 12.5, height: 1.35, color: p.ink2),
        ),
        if (_roleOption != null && _roleOption!.holds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Keeps: ${_roleOption!.holds.map((h) => h.sensitive ? '${h.label} (asks you first)' : h.label).join(', ')}.',
            style: TextStyle(fontSize: 12, height: 1.35, color: p.soft),
          ),
        ],
        if (_failed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text("That didn't go through. Try again.", style: TextStyle(color: StickPalette.alert, fontSize: 12.5)),
          ),
        const SizedBox(height: 14),
        SticksButton('Add to team', onTap: (!ready || _busy) ? null : () async {
          setState(() {
            _busy = true;
            _failed = false;
          });
          try {
            await s.data.createStick(
              fullName: _name.text.trim(),
              woman: _gender == StickGender.woman,
              roleKey: _role!,
              look: preview,
            );
            if (mounted) s.nav.back();
          } catch (_) {
            if (mounted) setState(() {
              _busy = false;
              _failed = true;
            });
          }
        }),
      ]),
    );
  }
}

/// A cone of white light from the top and a bright pool on the floor, blurred
/// soft. There is no floor line.
class _BeamPainter extends CustomPainter {
  final double floor;
  const _BeamPainter({required this.floor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cone = Path()
      ..moveTo(w * .39, 0)
      ..lineTo(w * .61, 0)
      ..lineTo(w * .91, floor)
      ..lineTo(w * .09, floor)
      ..close();
    final blur = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(
      cone,
      blur
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .3),
            Colors.white.withValues(alpha: .55),
            Colors.white.withValues(alpha: .78),
          ],
          stops: const [0, .7, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, floor)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, floor + 2), width: w * .84, height: 30),
      Paint()
        ..color = const Color(0xFFECECEC)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(_BeamPainter o) => o.floor != floor;
}
