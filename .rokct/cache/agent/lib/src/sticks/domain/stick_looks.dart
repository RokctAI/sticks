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

import 'dart:ui';

import 'stick_models.dart';

class _Clothes {
  final String name;
  final Color color;
  final Color shade;
  const _Clothes(this.name, this.color, this.shade);
}

const _womenClothes = [
  _Clothes('teal', Color(0xFF2F9C95), Color(0xFF237A74)),
  _Clothes('coral', Color(0xFFE8704F), Color(0xFFC25636)),
  _Clothes('plum', Color(0xFF8A5CC0), Color(0xFF7047A3)),
  _Clothes('mustard', Color(0xFFD9A62B), Color(0xFFB3871C)),
  _Clothes('rose', Color(0xFFD9647E), Color(0xFFB44A63)),
  _Clothes('sky', Color(0xFF5B9BD5), Color(0xFF437BAE)),
];

const _menClothes = [
  _Clothes('blue', Color(0xFF4C72B0), Color(0xFF3A5B93)),
  _Clothes('green', Color(0xFF5AA05A), Color(0xFF438544)),
  _Clothes('orange', Color(0xFFF0843F), Color(0xFFD26A2A)),
  _Clothes('slate', Color(0xFF4A5160), Color(0xFF373D4A)),
  _Clothes('burgundy', Color(0xFF9B3B49), Color(0xFF7C2D39)),
  _Clothes('olive', Color(0xFF8A8F3A), Color(0xFF6D712B)),
];

/// Hair styles by gender. The painter draws the same index; -1 is bald.
const womenHairStyles = [0, 1, 2, 3];
const menHairStyles = [4, 5, 6];

/// The item a role carries, by what the role is called. Roles are the
/// server's (`list_roles`); an unknown one carries nothing.
({StickProp prop, bool glasses, String line}) roleItem(String label) {
  final l = label.toLowerCase();
  if (l.contains('secret') || l.contains('reception')) {
    return (prop: StickProp.clipboard, glasses: false, line: 'a clipboard and headset');
  }
  if (l.contains('account') || l.contains('book') || l.contains('financ')) {
    return (prop: StickProp.calculator, glasses: true, line: 'a calculator and glasses');
  }
  if (l.contains('tender') || l.contains('bid')) {
    return (prop: StickProp.folder, glasses: false, line: 'a tender folder');
  }
  if (l.contains('sales')) return (prop: StickProp.phone, glasses: false, line: 'a phone');
  if (l.contains('market')) return (prop: StickProp.megaphone, glasses: false, line: 'a megaphone');
  if (l.contains('operat')) return (prop: StickProp.toolbox, glasses: false, line: 'a toolbox');
  return (prop: StickProp.none, glasses: false, line: 'nothing yet');
}

const _skins = [
  [Color(0xFFF7CD9C), Color(0xFFE8AE78)],
  [Color(0xFFB77B52), Color(0xFF93603D)],
];

int _hash(String s) {
  var h = 7;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0xFFFFFFFF;
  }
  return h;
}

List<T> _rot<T>(List<T> a, int n) {
  final k = n % a.length;
  return [...a.sublist(k), ...a.sublist(0, k)];
}

/// The uniqueness rule: a shirt or dress colour and a hair style already on
/// the team score against a candidate, and the least repeated one wins. The
/// seed is the gender and role, so the look does not flicker while a name is typed.
class StickLooks {
  const StickLooks._();

  static String colourName(StickGender g, Color c) {
    final list = g == StickGender.woman ? _womenClothes : _menClothes;
    for (final x in list) {
      if (x.color == c) return x.name;
    }
    return '';
  }

  static StickLook assign({
    required StickGender gender,
    required String roleKey,
    required String roleLabel,
    required List<StickLook> team,
    required List<String> teamRoles,
  }) {
    final item = roleItem(roleLabel);
    final clothes = gender == StickGender.woman ? _womenClothes : _menClothes;
    final hairs = gender == StickGender.woman ? womenHairStyles : menHairStyles;
    final seed = _hash('${gender.name}$roleKey');
    final skin = _skins[seed % _skins.length];

    var best = (clothes.first, hairs.first);
    var bestScore = 1 << 30;
    for (final c in _rot(clothes, seed)) {
      for (final h in _rot(hairs, seed >> 3)) {
        var score = 0;
        for (var i = 0; i < team.length; i++) {
          if (team[i].clothes == c.color) {
            score += 4;
            if (teamRoles[i] == roleLabel) score += 4;
          }
          if (team[i].hairStyle == h) score += 2;
        }
        if (score < bestScore) {
          bestScore = score;
          best = (c, h);
        }
      }
    }
    return StickLook(
      skin: skin[0],
      skinShade: skin[1],
      clothes: best.$1.color,
      clothesShade: best.$1.shade,
      hair: const Color(0xFF1E1A17),
      dress: gender == StickGender.woman,
      glasses: item.glasses,
      hairStyle: best.$2,
      prop: item.prop,
    );
  }

  /// A look from the server's hints (`skin`, `shirt`, `hair`, `hair_color`
  /// as hex or a hair name). Missing hints fall back to [base].
  static StickLook fromHints(Map<String, dynamic>? hints, StickLook base) {
    if (hints == null) return base;
    Color? hex(Object? v) {
      final t = v is String ? v.replaceFirst('#', '') : '';
      final n = t.length == 6 ? int.tryParse(t, radix: 16) : null;
      return n == null ? null : Color(0xFF000000 | n);
    }

    Color shade(Color c) => Color.lerp(c, const Color(0xFF000000), .14)!;
    final skin = hex(hints['skin']);
    final shirt = hex(hints['shirt']);
    final hair = hex(hints['hair_color']);
    const styles = {'none': -1, 'ponytail': 1, 'cap': 4, 'bob': 2};
    return StickLook(
      skin: skin ?? base.skin,
      skinShade: skin == null ? base.skinShade : shade(skin),
      clothes: shirt ?? base.clothes,
      clothesShade: shirt == null ? base.clothesShade : shade(shirt),
      hair: hair ?? base.hair,
      dress: base.dress,
      glasses: base.glasses,
      hairStyle: styles[hints['hair']] ?? base.hairStyle,
      prop: base.prop,
    );
  }

  /// The line setup shows under the chips, in the intro's wording.
  static String why({
    required StickGender gender,
    required String roleLabel,
    required StickLook look,
    required List<StickLook> team,
    required List<String> teamNames,
    required List<String> teamRoles,
  }) {
    final colour = colourName(gender, look.clothes);
    final taken = team.any((t) => t.clothes == look.clothes);
    final head = taken
        ? 'Every colour is taken, so this is the least repeated. '
        : '${_cap(colour)} is free and ${gender == StickGender.woman ? 'women get a dress' : 'men get a shirt'}. ';
    final i = teamRoles.indexOf(roleLabel);
    final same = i >= 0 ? '${teamNames[i]} already has this role, so the clothes and hair are different. ' : '';
    return '$head${same}Item: ${roleItem(roleLabel).line}.';
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
