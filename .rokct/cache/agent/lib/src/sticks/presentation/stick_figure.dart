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

import '../domain/stick_models.dart';

const _ink = Color(0xFF141414);

/// Parses the small subset of SVG path data the Stick drawings use
/// (M L H V Q Z, absolute and relative) so the shapes stay the same numbers
/// as the design files.
Path svgPath(String d) {
  final p = Path();
  final t = RegExp(r'([MLHVQZmlhvqz])|(-?\d*\.?\d+)')
      .allMatches(d)
      .map((m) => m.group(0)!)
      .toList();
  var i = 0;
  var cmd = 'M';
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  double n() => double.parse(t[i++]);
  bool isCmd(String s) => RegExp(r'^[MLHVQZmlhvqz]$').hasMatch(s);
  while (i < t.length) {
    if (isCmd(t[i])) cmd = t[i++];
    switch (cmd) {
      case 'M':
        x = n(); y = n(); sx = x; sy = y; p.moveTo(x, y); cmd = 'L';
      case 'm':
        x += n(); y += n(); sx = x; sy = y; p.moveTo(x, y); cmd = 'l';
      case 'L':
        x = n(); y = n(); p.lineTo(x, y);
      case 'l':
        x += n(); y += n(); p.lineTo(x, y);
      case 'H':
        x = n(); p.lineTo(x, y);
      case 'h':
        x += n(); p.lineTo(x, y);
      case 'V':
        y = n(); p.lineTo(x, y);
      case 'v':
        y += n(); p.lineTo(x, y);
      case 'Q':
        final cx = n(), cy = n(); x = n(); y = n();
        p.quadraticBezierTo(cx, cy, x, y);
      case 'q':
        final cx = x + n(), cy = y + n(); x += n(); y += n();
        p.quadraticBezierTo(cx, cy, x, y);
      case 'Z':
      case 'z':
        p.close(); x = sx; y = sy;
    }
  }
  return p;
}

enum StickCrop { full, head, peek }

/// One Stick, drawn from the design's 200 x 280 drawing. [crop] shows the
/// whole body, the head on a round avatar, or the head peeking over a sheet.
/// In [dark] the Stick keeps its colours; only a thin white outline is added
/// around the black lines, cut off above the ground shadow so it never
/// touches it.
class StickFigure extends StatelessWidget {
  final StickLook look;
  final StickMood mood;
  final StickCrop crop;
  final bool dark;
  final double outlineAlpha;
  final bool shadow;

  const StickFigure({
    super.key,
    required this.look,
    this.mood = StickMood.neutral,
    this.crop = StickCrop.full,
    this.dark = false,
    this.outlineAlpha = .4,
    this.shadow = true,
  });

  static const _boxes = {
    StickCrop.full: Rect.fromLTWH(0, 0, 200, 280),
    StickCrop.head: Rect.fromLTWH(40, 16, 120, 120),
    StickCrop.peek: Rect.fromLTWH(30, 14, 140, 117),
  };

  @override
  Widget build(BuildContext context) {
    final box = _boxes[crop]!;
    return AspectRatio(
      aspectRatio: box.width / box.height,
      child: CustomPaint(
        painter: StickPainter(
          look: look,
          mood: mood,
          view: box,
          dark: dark,
          outlineAlpha: outlineAlpha,
          shadow: shadow && crop == StickCrop.full,
        ),
      ),
    );
  }
}

class StickPainter extends CustomPainter {
  final StickLook look;
  final StickMood mood;
  final Rect view;
  final bool dark;
  final double outlineAlpha;
  final bool shadow;

  const StickPainter({
    required this.look,
    required this.mood,
    required this.view,
    required this.dark,
    required this.outlineAlpha,
    required this.shadow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / view.width, size.height / view.height);
    canvas.translate(-view.left, -view.top);
    canvas.clipRect(view);
    if (shadow) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(100, 267), width: 80, height: 12),
        Paint()..color = Colors.black.withValues(alpha: dark ? .3 : .14),
      );
    }
    if (dark) {
      canvas.save();
      canvas.clipRect(const Rect.fromLTRB(-2000, -2000, 4000, 259));
      _Drawing(canvas, look, mood, halo: Colors.white.withValues(alpha: outlineAlpha)).draw();
      canvas.restore();
    }
    _Drawing(canvas, look, mood).draw();
    canvas.restore();
  }

  @override
  bool shouldRepaint(StickPainter o) =>
      o.look != look || o.mood != mood || o.dark != dark || o.view != view ||
      o.outlineAlpha != outlineAlpha || o.shadow != shadow;
}

class _Drawing {
  final Canvas c;
  final StickLook look;
  final StickMood mood;

  /// When set, only the black lines are drawn, as a wider stroke in this
  /// colour; everything else is skipped.
  final Color? halo;

  _Drawing(this.c, this.look, this.mood, {this.halo});

  bool get _h => halo != null;

  void _line(String d, double w) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _h ? w + 2.8 : w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _h ? halo! : _ink;
    c.drawPath(svgPath(d), paint);
  }

  void _dot(double x, double y, double r) {
    c.drawCircle(Offset(x, y), _h ? r + 1.4 : r, Paint()..color = _h ? halo! : _ink);
  }

  /// A coloured shape with the black outline; in halo mode only the outline.
  void _shape(Path p, {required Paint fill, double w = 4}) {
    if (!_h) c.drawPath(p, fill);
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _h ? w + 2.8 : w
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = _h ? halo! : _ink,
    );
  }

  Paint _flat(Color col) => Paint()..color = col;

  Paint _split(Rect r, Color a, Color b) => Paint()
    ..shader = LinearGradient(
      colors: [a, a, b, b],
      stops: const [0, .7, .7, 1],
    ).createShader(r);

  void draw() {
    _legs();
    _torso();
    _armsAndProp();
    _head();
  }

  void _legs() {
    _line('M90 204 L86 262', 4);
    _line('M110 204 L114 262', 4);
    for (final d in ['M86 262 L74 263 Q70 266 76 267 L88 266 Z', 'M114 262 L126 263 Q130 266 124 267 L112 266 Z']) {
      final p = svgPath(d);
      c.drawPath(p, Paint()..color = _h ? halo! : _ink);
      c.drawPath(p, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _h ? 5.8 : 3
        ..strokeJoin = StrokeJoin.round
        ..color = _h ? halo! : _ink);
    }
  }

  void _torso() {
    final dress = look.dress;
    final body = svgPath(dress
        ? 'M78 126 L122 126 Q126 126 126 132 L128 168 L144 226 Q100 234 56 226 L72 168 L74 132 Q74 126 78 126 Z'
        : 'M78 126 L122 126 Q126 126 126 132 L129 204 Q100 208 71 204 L74 132 Q74 126 78 126 Z');
    _shape(body,
        fill: _split(body.getBounds(), look.clothes, look.clothesShade), w: 4.5);
    if (dress) _line('M76 166 Q100 172 124 166', 3);
    if (look.prop == StickProp.calculator) {
      final collar = svgPath('M86 126 L100 138 L114 126');
      if (!_h) c.drawPath(collar, _flat(const Color(0xFFF4F1EA)));
      c.drawPath(collar, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _h ? 5.8 : 3
        ..strokeJoin = StrokeJoin.round
        ..color = _h ? halo! : _ink);
      final tie = svgPath('M100 138 L96 146 L100 178 L104 146 Z');
      if (!_h) c.drawPath(tie, _flat(const Color(0xFFB8343A)));
      c.drawPath(tie, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _h ? 5.3 : 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = _h ? halo! : _ink);
    }
  }

  void _hand(double x, double y) => _dot(x, y, 4.5);

  void _armsAndProp() {
    switch (look.prop) {
      case StickProp.calculator:
        _line('M76 134 Q66 168 72 196', 4); _hand(72, 197);
        _line('M124 134 Q140 150 136 162', 4); _hand(136, 162);
        _calculator();
      case StickProp.clipboard:
        _clipboard();
        _line('M76 134 Q64 158 66 170', 4); _hand(66, 171);
        _line('M124 132 Q158 124 166 96', 4); _hand(167, 93);
      case StickProp.folder:
        _folder();
        _line('M76 134 Q62 156 64 170', 4); _hand(64, 170);
        _line('M124 134 Q138 156 128 168', 4); _hand(128, 168);
      case StickProp.phone:
        _line('M76 134 Q62 160 68 186', 4); _hand(68, 187);
        _line('M124 134 Q152 128 148 102', 4); _hand(148, 100);
        _phone();
      case StickProp.megaphone:
        _line('M76 134 Q66 168 72 196', 4); _hand(72, 197);
        _line('M124 134 Q150 130 150 106', 4); _hand(150, 104);
        _megaphone();
      case StickProp.toolbox:
        _line('M76 134 Q66 168 72 196', 4); _hand(72, 197);
        _line('M124 134 Q132 170 128 188', 4); _hand(128, 189);
        _toolbox();
      case StickProp.coffee:
        _line('M76 134 Q66 168 72 196', 4); _hand(72, 197);
        _line('M124 134 Q134 160 142 160', 4); _hand(143, 160);
        _coffee();
      case StickProp.none:
        _line('M76 134 Q70 168 72 196', 4); _hand(72, 197);
        _line('M124 134 Q130 168 128 196', 4); _hand(128, 197);
    }
  }

  void _box(String d, Color fill, {double w = 3}) {
    _shape(svgPath(d), fill: _flat(fill), w: w);
  }

  void _calculator() {
    final r = RRect.fromRectAndRadius(const Rect.fromLTWH(132, 146, 24, 34), const Radius.circular(3));
    final p = Path()..addRRect(r);
    _shape(p, fill: _flat(const Color(0xFF4B4B4B)));
    if (_h) return;
    c.drawRect(const Rect.fromLTWH(136, 150, 16, 7), _flat(const Color(0xFFC2E5B6)));
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        c.drawRect(Rect.fromLTWH(136.0 + i * 6, 160.0 + j * 6, 4, 4), _flat(const Color(0xFFECE6DA)));
      }
    }
  }

  void _clipboard() {
    _box('M46 152 L74 152 L74 188 L46 188 Z', const Color(0xFFC49A62));
    if (_h) return;
    c.drawRect(const Rect.fromLTWH(50, 158, 20, 26), _flat(const Color(0xFFFFFAF1)));
    for (final y in [164.0, 170.0, 176.0]) {
      c.drawLine(Offset(53, y), Offset(y == 176 ? 62 : 67, y), Paint()..color = const Color(0xFF9A9A9A)..strokeWidth = 1.8);
    }
  }

  void _folder() {
    _box('M58 150 L126 146 L130 190 L62 194 Z', const Color(0xFFE3C27A), w: 4);
    if (_h) return;
    c.save();
    c.translate(94, 170);
    c.rotate(-0.105);
    c.translate(-94, -170);
    c.drawRect(const Rect.fromLTWH(74, 162, 40, 15), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFFB33B2E));
    c.restore();
  }

  void _phone() {
    c.save();
    c.translate(148, 90);
    c.rotate(0.21);
    c.translate(-148, -90);
    _shape(Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(142, 78, 13, 24), const Radius.circular(3))),
        fill: _flat(const Color(0xFF2A2A2A)), w: 2.5);
    c.restore();
  }

  void _megaphone() {
    _box('M144 96 L168 84 L168 118 L144 108 Z', const Color(0xFFE0533D));
    _box('M136 96 L144 96 L144 108 L136 108 Z', const Color(0xFF8D939C), w: 2.5);
  }

  void _toolbox() {
    _box('M108 186 L148 186 L148 212 L108 212 Z', const Color(0xFFC0392B));
    _line('M120 186 L120 180 L136 180 L136 186', 3);
  }

  void _coffee() {
    _box('M140 150 L156 150 L154 170 L142 170 Z', const Color(0xFFFBF7EF));
    _box('M139 150 L157 150 L156 145 L140 145 Z', const Color(0xFF6B4A33));
    if (!_h) c.drawRect(const Rect.fromLTWH(141, 156, 14, 7), _flat(const Color(0xFFC98F5A)));
  }

  // ---- head -----------------------------------------------------------

  void _head() {
    final centre = const Offset(100, 80);
    _hairBack();
    final skinPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.24, -.36),
        radius: .75,
        colors: [look.skin, look.skin, look.skinShade],
        stops: const [0, .62, 1],
      ).createShader(Rect.fromCircle(center: centre, radius: 50));
    if (!_h) c.drawCircle(centre, 50, skinPaint);
    c.drawCircle(centre, 50, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _h ? 8.3 : 5.5
      ..color = _h ? halo! : _ink);
    _hairFront();
    if (look.glasses) {
      for (final x in [87.0, 113.0]) {
        c.drawCircle(Offset(x, 80), 11, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _h ? 5.8 : 3
          ..color = _h ? halo! : _ink);
      }
      _line('M98 79 Q100 76 102 79 M76 78 L54 72 M124 78 L146 72', 3);
    }
    _face();
  }

  void _hairShape(String d, {double w = 4}) =>
      _shape(svgPath(d), fill: _flat(look.hair), w: w);

  void _hairBack() {
    switch (look.hairStyle) {
      case 1:
        _hairShape('M140 66 Q166 70 162 100 Q156 86 142 84');
        if (!_h) c.drawCircle(const Offset(141, 70), 5, _flat(const Color(0xFFE0533D)));
      case 2:
        _hairShape('M48 70 Q42 130 56 152 L70 150 Q64 120 66 80 Z M152 70 Q158 130 144 152 L130 150 Q136 120 134 80 Z');
      case 3:
        _hairShape('M86 32 Q100 14 114 32 Q100 40 86 32 Z');
    }
  }

  void _hairFront() {
    switch (look.hairStyle) {
      case 0:
      case 3:
        _hairShape('M52 82 Q50 32 100 30 Q146 30 150 74 Q134 52 108 50 Q84 58 64 60 Q56 68 52 82 Z');
      case 1:
        _hairShape('M52 82 Q50 32 100 30 Q146 30 150 74 Q134 52 108 50 Q84 58 64 60 Q56 68 52 82 Z');
        _line('M52 92 Q46 46 100 32 Q150 40 148 84', 3.5);
      case 2:
        _hairShape('M52 80 Q50 32 100 30 Q150 32 148 80 Q130 54 100 54 Q72 54 52 80 Z');
      case 4:
        _hairShape('M54 70 Q56 30 100 30 Q144 30 146 70 Q122 48 100 50 Q76 48 54 70 Z');
      case 5:
        _hairShape('M54 68 Q54 26 100 26 Q146 26 146 68 L140 52 Q100 44 60 52 Z');
      case 6:
        _hairShape('M52 72 Q54 30 104 30 Q146 32 148 72 Q128 46 92 54 Q66 60 52 72 Z');
    }
  }

  void _face() {
    const faces = {
      StickMood.neutral: ['', 'M95 104 L106 104'],
      StickMood.happy: ['', 'M92 101 Q100 108 108 101'],
      StickMood.worried: ['M80 70 Q86 64 92 68 M108 68 Q114 64 120 70', 'M92 106 Q100 99 108 106'],
      StickMood.focus: ['M79 66 L92 71 M121 66 L108 71', 'M94 104 Q100 102 106 104'],
      StickMood.glad: ['M80 66 Q86 62 92 66 M108 66 Q114 62 120 66', 'M90 99 Q100 112 110 99 Z'],
    };
    final f = faces[mood]!;
    if (mood == StickMood.glad) {
      _line('M81 81 Q87 74 93 81 M107 81 Q113 74 119 81', 4);
    } else {
      _dot(87, 80, 5.2);
      _dot(113, 80, 5.2);
    }
    if (f[0].isNotEmpty) _line(f[0], 3);
    final mouth = svgPath(f[1]);
    if (mood == StickMood.glad && !_h) c.drawPath(mouth, _flat(const Color(0xFF6E2F2A)));
    _line(f[1], 3);
  }
}
