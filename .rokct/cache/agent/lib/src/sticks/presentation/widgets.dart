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
import 'stick_figure.dart';
import 'sticks_scope.dart';

TextStyle sticksHead(BuildContext context, double size, {Color? color}) =>
    TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      height: 1.1,
      color: color ?? StickPalette.of(context).ink,
    );

TextStyle sticksLabel(BuildContext context, double size, {Color? color}) =>
    TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color ?? StickPalette.of(context).ink,
    );

/// A screen's title block: optional back link, heading, one soft line.
class StickTop extends StatelessWidget {
  final String title;
  final String? sub;
  final String? back;
  final Widget? trailing;

  const StickTop({super.key, required this.title, this.sub, this.back, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (back != null)
          GestureDetector(
            onTap: SticksScope.of(context).nav.back,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('‹ $back', style: sticksLabel(context, 13, color: p.soft)),
            ),
          ),
        Row(children: [
          Expanded(child: Text(title, style: sticksHead(context, 25))),
          if (trailing != null) trailing!,
        ]),
        if (sub != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(sub!, style: TextStyle(color: p.soft, fontSize: 13.5)),
          ),
      ],
    );
  }
}

/// A Stick's head in a coloured ring.
class StickRing extends StatelessWidget {
  final Stick stick;
  final double size;
  final bool live;

  const StickRing({super.key, required this.stick, this.size = 56, this.live = false});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(stick.accent.withValues(alpha: .22), p.card),
        boxShadow: live ? [BoxShadow(color: stick.accent, spreadRadius: 2.5)] : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: StickFigure(look: stick.look, mood: stick.mood, crop: StickCrop.head, dark: p.dark),
    );
  }
}

class SticksCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const SticksCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.rule),
      ),
      child: child,
    );
  }
}

class SticksButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool quiet;

  const SticksButton(this.label, {super.key, this.onTap, this.filled = true, this.quiet = false});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    final fg = filled ? p.onInk : (quiet ? p.soft : p.ink);
    return Opacity(
      opacity: onTap == null ? .35 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: filled ? p.ink : p.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: quiet ? p.rule : p.ink, width: 2),
          ),
          child: Text(label, style: sticksLabel(context, 14.5, color: fg)),
        ),
      ),
    );
  }
}

class SticksChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback? onTap;

  const SticksChip(this.label, {super.key, this.on = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: on ? p.ink : p.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? p.ink : p.rule),
        ),
        child: Text(label, style: sticksLabel(context, 12, color: on ? p.onInk : p.ink)),
      ),
    );
  }
}

class SticksBar extends StatelessWidget {
  final double value;
  final Color color;

  const SticksBar(this.value, {super.key, this.color = StickPalette.working});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 6,
        backgroundColor: p.rule,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class SticksSectionLabel extends StatelessWidget {
  final String text;
  const SticksSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(text.toUpperCase(),
            style: sticksLabel(context, 11.5, color: StickPalette.of(context).soft)
                .copyWith(letterSpacing: 1.4)),
      );
}

/// A screen body with a loading and an error state, so no screen shows a
/// blank page while the data source answers.
class SticksFuture<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext, T) builder;

  const SticksFuture({super.key, required this.future, required this.builder});

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text("Couldn't load this. Pull to try again.",
                  style: TextStyle(color: StickPalette.of(context).soft)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return builder(context, snap.data as T);
        },
      );
}

/// A sheet that rises over a Stick, so only the head peeks above it.
class CoveredSheet extends StatelessWidget {
  final Stick stick;
  final StickMood? mood;
  final Widget child;

  const CoveredSheet({super.key, required this.stick, required this.child, this.mood});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    return Column(children: [
      SizedBox(
        width: 118,
        child: StickFigure(look: stick.look, mood: mood ?? stick.mood, crop: StickCrop.peek, dark: p.dark),
      ),
      Expanded(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.card,
            border: Border(top: BorderSide(color: p.ink, width: 3)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: child,
        ),
      ),
    ]);
  }
}

/// Who a message is from or to: a Stick, the owner, or reception.
class Party {
  final String name;
  final Stick? stick;
  const Party(this.name, this.stick);

  static Party of(String id, List<Stick> team) {
    if (id == 'owner') return const Party('You', null);
    if (id == 'reception') {
      final sec = team.where((x) => x.role.toLowerCase().contains('secret')).firstOrNull;
      return Party('Reception', sec);
    }
    final st = team.where((x) => x.id == id).firstOrNull;
    return Party(st?.name ?? id.split('@').first, st);
  }
}

/// A round head for a [Party]: the Stick's head, or a plain disc for the owner.
class PartyAvatar extends StatelessWidget {
  final Party party;
  final double size;
  const PartyAvatar(this.party, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final p = StickPalette.of(context);
    if (party.stick != null) return StickRing(stick: party.stick!, size: size);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: p.ink),
      child: Text(party.name.isEmpty ? '?' : party.name[0], style: sticksHead(context, size * .4, color: p.onInk)),
    );
  }
}

String clockTime(DateTime? t) => t == null
    ? ''
    : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String shortDate(DateTime? t) {
  if (t == null) return '';
  const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${t.day} ${mo[t.month - 1]}, ${clockTime(t)}';
}
