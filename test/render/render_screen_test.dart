// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Render harness for the shared review-strip kit (RokctAI/shared-workflows
// scripts/render/README.md, templates/render-harness/render_screen_test.dart).
//
// Screen: the Sticks TEAM page - SticksShell at its first tab, the app's home
// (agent_sdk's `sticks` flavor). It is the screen the sticks tour opens on,
// and the one the review must show first.
//
// The screen comes from agent_sdk's Sticks flavor, `package:agent_sdk/sticks.dart`,
// which is only composed into the `sticks` app_type. The harness wraps it in
// the same SticksScope + SticksPage host the installed sticks_pages.dart
// uses, so the screen is the real one, not a copy.
//
// Everything below the "proven mechanism" banner is the kit's, unchanged.
//
// This runs against the COMPOSED app - `lib/` and the SDK caches only exist
// after `.rokct` compose, so the imports below resolve on a composed tree only.
//
// Data: a demo session is activated and the SDKs register their REAL
// repositories. StickRepository reads the `api.sticks.*` cmds on the platform
// gateway, and base_sdk's DemoGatewayInterceptor answers them from agent_sdk's
// own fixtures (assets/demo/sticks).
//
// Run:  flutter test test/render/render_screen_test.dart
//       RENDER_SUFFIX=_draft flutter test test/render/render_screen_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
// The offline seam google_fonts documents for tests (see the polaris harness).
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auth_sdk/auth_sdk.dart' show AuthSdkDependencies;
// ignore: implementation_imports
import 'package:auth_sdk/src/common/services/session_profile.dart'
    show sessionProfileOf;
import 'package:base_sdk/base_sdk.dart'
    show
        BaseSdkDependencies,
        DemoSession,
        FloatingBottomNav,
        LocalStorage,
        PlatformGateway;
// Deep imports into base_sdk's src/ are expected in a harness (the kit's
// template says so): the auth facade is not on the base_sdk barrel.
import 'package:base_sdk/src/domain/interface/auth.dart'
    show AuthRepositoryFacade;
// ApiResult's `when` is an extension declared in its freezed part.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart' show AppStyle;
import 'package:users_sdk/users_sdk.dart' show UsersSdkDependencies;

// agent_sdk's DI is not on the barrel (the Sticks flavor is app_type gated),
// so the registration is imported from its src path, as the template allows.
// ignore: implementation_imports
import 'package:agent_sdk/src/common/di/agent_di.dart'
    show AgentSdkDependencies;
import 'package:agent_sdk/sticks.dart';

import 'vector_svg.dart';

// ---------------------------------------------------------------------------
// Render settings - phone size the reviews are judged at.
// ---------------------------------------------------------------------------

/// Logical width of the frame (iPhone-class phone).
const double kLogicalWidth = 390;

/// Device pixel ratio the PNG is captured at (3 = @3x).
const double kDevicePixelRatio = 3.0;

/// Tall probe viewport for the first pass. Must exceed the tallest screen.
const double kProbeHeight = 2600;

/// Slack below the last element in the final frame, in logical pixels.
const double kBottomPadding = 20;

/// Phone height used when the content is taller than [kProbeHeight] and
/// cannot be shrunk to fit (iPhone 12-15 class, 390 x 844).
const double kDeviceHeight = 844;

/// How long (real time) the harness waits for the demo data to land before
/// it fails the test instead of capturing an empty or loading screen.
const Duration kReadyTimeout = Duration(seconds: 30);

/// The app's design size, straight from the composed app_widget.
const Size kDesignSize = Size(375, 812);

// ---------------------------------------------------------------------------
// The demo wiring. Registrations run in composed-app order.
// ---------------------------------------------------------------------------

/// Step 2/8 - the SDK's own demo data. THIS IS THE MAIN PATH.
///
/// Registers the shared kernel, the auth/user SDKs and agent_sdk. The Sticks
/// screens read the `api.sticks.*` cmds through the platform gateway, which
/// the demo interceptor answers from agent_sdk's fixtures.
Future<void> registerDemoDependencies() async {
  assert(
      DemoSession.demoActive,
      'demo session not active: the real repositories would call a live '
      'backend and the render is of a broken, empty screen');
  final getIt = GetIt.I;
  BaseSdkDependencies.register(getIt);
  AuthSdkDependencies.register(getIt);
  UsersSdkDependencies.register(getIt);
  AgentSdkDependencies.register(getIt);
}

/// Step 3/8 - EXCEPTION: device history the demo mode cannot supply.
///
/// EMPTY. The team, tasks and asks are the demo fixtures; nothing the device
/// accumulates through use is needed for the team page.
Future<void> seedDeviceHistory(WidgetTester tester) async {}

/// Step 4/8 - EXCEPTION: stub a service with no demo implementation.
///
/// EMPTY. StickRepository answers from the demo fixtures, so nothing is stubbed.
void registerExceptionStubs() {}

/// Step 5/8 - register sections / routes / gates.
///
/// Nothing to register: the Sticks shell has no section registry.
void registerScreen() {}

/// Routes the Sticks screens through the harness. The team page is rendered
/// as the first frame, so no navigation is exercised: every call is a no-op.
class _HarnessNav implements SticksNav {
  @override
  void openStick(String id) {}
  @override
  void openProfile(String id) {}
  @override
  void openTask(String id) {}
  @override
  void openAsk(String stickId) {}
  @override
  void openGiveTask({String? stickId}) {}
  @override
  void openHire() {}
  @override
  void openSetup({String? role, bool animated = false}) {}
  @override
  void openReport() {}
  @override
  void openTalk() {}
  @override
  void openInbox({String? forWho}) {}
  @override
  void openCalls() {}
  @override
  void openSettings() {}
  @override
  void openLock() {}
  @override
  void back() {}
}

/// Step 6/8 - the widget under test.
///
/// The real Sticks home in the host's own wrapping: SticksScope carries the
/// data source and navigation, SticksPage carries the Sticks chrome, and
/// SticksShell at tab 0 is the team page. Same composition as the installed
/// sticks_pages.dart's SticksHomePage.
Widget buildScreen({required bool dark}) {
  return ProviderScope(
    child: ScreenUtilInit(
      useInheritedMediaQuery: false,
      designSize: kDesignSize,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          useMaterial3: false,
        ),
        home: SticksScope(
          data: StickRepository(const PlatformGateway().tenant),
          nav: _HarnessNav(),
          child: const SticksPage(child: SticksShell()),
        ),
      ),
    ),
  );
}

/// Step 7/8 - the elements the review points at.
///
/// `key` is the stable identity the composer binds a number to for the life
/// of the page; the committed map lives in test/render/strip.json.
List<ElementSpec> elementSpecs() {
  return <ElementSpec>[
    ElementSpec(
      key: 'sticks.team_screen',
      label: 'Team page - your Sticks and their status',
      finder: find.byType(TeamScreen),
    ),
    ElementSpec.each(
      keyOf: (i, w) => 'sticks.team.stick_${i + 1}',
      labelOf: (i, w) => 'Stick ${i + 1} - team row with figure and status',
      finder: find.byType(StickFigure),
    ),
    ElementSpec(
      key: 'sticks.tab_bar',
      label: 'Tab bar - Team, Tasks, Asks, Reports',
      // The shell's tab bar is base_sdk's shared FloatingBottomNav. (SticksBar
      // is agent_sdk's progress bar - matching it here never found the tabs.)
      finder: find.byType(FloatingBottomNav),
    ),
  ];
}

/// What must be on screen before the frame is captured: the demo team rows
/// (one StickFigure per Stick) AND the tab bar (FloatingBottomNav). Capture also waits for every
/// CircularProgressIndicator to be gone. If this is not true within
/// [kReadyTimeout] the test FAILS rather than writing a blank or spinning
/// frame.
List<Finder> readyFinders() => <Finder>[
      find.descendant(
          of: find.byType(TeamScreen), matching: find.byType(StickFigure)),
      find.byType(FloatingBottomNav),
    ];

// ---------------------------------------------------------------------------
// Step 8/8 - real fonts.
//
// Without real faces every glyph renders as the Ahem/FlutterTest block font
// and the PNG is worthless, so a missing face is a HARD FAILURE here.
// The faces are COMMITTED under test/render/fonts/, named by the SHA-256
// google_fonts checks each file against, and served back through
// google_fonts' own @visibleForTesting http seam.
// ---------------------------------------------------------------------------

/// Directory holding the committed Google faces. `RENDER_FONT_DIR` points the
/// harness at a different directory for a local experiment.
String _fontDir() {
  final override = Platform.environment['RENDER_FONT_DIR'];
  if (override != null && override.isNotEmpty) return override;
  return '${Directory.current.path}/test/render/fonts';
}

/// Serves google_fonts' own font URLs from the committed faces.
class _OfflineGoogleFontsClient extends http.BaseClient {
  _OfflineGoogleFontsClient(this.fontsDir);

  final Directory fontsDir;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final file = File('${fontsDir.path}/${request.url.pathSegments.last}');
    if (!file.existsSync()) {
      return http.StreamedResponse(
        const Stream<List<int>>.empty(),
        404,
        request: request,
        reasonPhrase:
            'not committed under test/render/fonts - see its README to add it',
      );
    }
    final bytes = file.readAsBytesSync();
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      contentLength: bytes.length,
      request: request,
    );
  }
}

/// First match for [pattern] under [root], or null.
File? _findFile(Directory root, RegExp pattern) {
  if (!root.existsSync()) return null;
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is File && pattern.hasMatch(entity.path)) return entity;
  }
  return null;
}

Future<void> loadRealFonts() async {
  Future<void> load(String family, List<File> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
    VectorSvgFonts.register(family, files);
  }

  final fontsDir = Directory(_fontDir());
  if (!fontsDir.existsSync()) {
    throw StateError(
      'no committed Google faces at ${fontsDir.path} - every glyph would fall '
      'back to the FlutterTest block font and the render would be worthless.',
    );
  }
  google_fonts_base.httpClient = _OfflineGoogleFontsClient(fontsDir);
  VectorSvgFonts.scanDirectory(fontsDir);

  await GoogleFonts.pendingFonts(<TextStyle>[
    GoogleFonts.inter(fontWeight: FontWeight.w400),
    GoogleFonts.inter(fontWeight: FontWeight.w500),
    GoogleFonts.inter(fontWeight: FontWeight.w600),
    GoogleFonts.inter(fontWeight: FontWeight.w700),
    GoogleFonts.montserrat(fontWeight: FontWeight.w400),
    GoogleFonts.montserrat(fontWeight: FontWeight.w700),
    GoogleFonts.montserrat(fontWeight: FontWeight.w900),
    GoogleFonts.montserrat(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
    ),
    GoogleFonts.montserrat(
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
    ),
    GoogleFonts.montserrat(
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
    ),
  ]);

  final roboto = File(
    '${fontsDir.path}/'
    'd1d7c5f4500eeb1a09e051781906c3642015a3f6c9b69046b905c8bf34c6ad60.ttf',
  );
  if (!roboto.existsSync()) {
    throw StateError('Roboto 400 missing at ${roboto.path} - every bare '
        'TextStyle would render as the FlutterTest block font');
  }
  await load('Roboto', <File>[roboto]);

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    throw StateError('FLUTTER_ROOT is unset, so MaterialIcons cannot be '
        'registered and every icon would render as a blank box');
  }
  await load('MaterialIcons', <File>[
    File('$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf')
  ]);

  final pubCache = Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME']}/.pub-cache';
  final remix = _findFile(Directory(pubCache),
      RegExp(r'remixicon-[^/\\]+[/\\]fonts[/\\]Remix\.ttf'));
  if (remix == null) {
    throw StateError('Remix.ttf not found under $pubCache - every Remix icon '
        'on the page would render as a blank box');
  }
  await load('packages/remixicon/Remix', <File>[remix]);

  await _loadAgentSdkFonts(load);
}

/// The Sticks screens draw every word in agent_sdk's OWN bundled faces
/// (agent/dart pubspec `fonts:` - Montserrat for headings, Nunito for body),
/// asked for as `TextStyle(fontFamily: 'Montserrat', package: 'agent_sdk')`,
/// i.e. the family `packages/agent_sdk/Montserrat`. A widget test never reads
/// the pubspec font manifest, so without this every Sticks label renders as
/// the FlutterTest block font. They are registered under BOTH names: the
/// package-qualified one the widgets use, and the plain one for any style
/// that drops `package:`.
Future<void> _loadAgentSdkFonts(
    Future<void> Function(String family, List<File> files) load) async {
  final root = _packageRoot('agent_sdk');
  if (root == null) {
    throw StateError('agent_sdk is not in .dart_tool/package_config.json - '
        'run the compose and `flutter pub get` first');
  }
  final fontsDir = Directory('${root.path}/lib/assets/fonts');
  for (final family in const <String>['Montserrat', 'Nunito']) {
    final files = fontsDir.existsSync()
        ? (fontsDir
            .listSync()
            .whereType<File>()
            .where((f) =>
                f.uri.pathSegments.last.startsWith('$family-') &&
                f.path.endsWith('.ttf'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
        : <File>[];
    if (files.isEmpty) {
      throw StateError('no $family-*.ttf under ${fontsDir.path} - every Sticks '
          'label would render as the FlutterTest block font');
    }
    await load('packages/agent_sdk/$family', files);
    await load(family, files);
  }
}

/// Root directory of [package] as `flutter pub get` resolved it, or null.
Directory? _packageRoot(String package) {
  final config =
      File('${Directory.current.path}/.dart_tool/package_config.json');
  if (!config.existsSync()) return null;
  final json = jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
  for (final entry in (json['packages'] as List<dynamic>)) {
    final p = entry as Map<String, dynamic>;
    if (p['name'] != package) continue;
    final rootUri = config.uri.resolve(p['rootUri'] as String);
    return Directory.fromUri(rootUri);
  }
  return null;
}

/// App-wide state the screen reads before it builds, in main.dart's order.
Future<void> primeAppState({required bool dark}) async {
  // Each variant starts from nothing: no registrations, no session, no
  // preferences left behind by the variant before it. Without this the
  // second (light) frame never got past its loading spinner.
  //
  // rootBundle is the culprit that matters: it caches each loadString FUTURE,
  // and base_sdk's DemoGatewayInterceptor reads every demo fixture through
  // it. A load the first variant started inside its own fake-async zone and
  // never finished stays in that cache, and the next variant awaits it
  // forever. Clearing the cache makes every variant load its own fixtures.
  rootBundle.clear();
  await GetIt.I.reset();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await LocalStorage.init();
  await LocalStorage.setAppThemeMode(dark);
  await DemoSession.instance.activate();
  AppStyle.setBrightness(dark ? Brightness.dark : Brightness.light);
}

/// The demo persona the tour signs in as (tour/app.tour.yaml setup.demo_email).
const String kDemoEmail = 'customer@demo.rokct.ai';

/// Persists the demo persona through the REAL AuthRepositoryFacade.login,
/// answered by auth_sdk's fixture, and stores the mapped account through the
/// app's real LocalStorage.setUser. The auth token is left EMPTY on purpose.
Future<void> persistDemoUser() async {
  final auth = GetIt.I<AuthRepositoryFacade>();
  final result = await auth.login(email: kDemoEmail, password: 'demo');
  await result.when(
    success: (data) async {
      final user = data.data?.user;
      if (user == null) {
        throw StateError('the api.user.login fixture returned no user');
      }
      await LocalStorage.setUser(sessionProfileOf(user));
    },
    failure: (error, status) async {
      throw StateError('demo sign-in failed ($status): $error - is the demo '
          'session active and does auth_sdk ship an api.user.login fixture?');
    },
  );
}

// ===========================================================================
// Below here is the mechanism (kit template). It waits for the screen to be
// ready (no fixed sleep), fits the frame to the real content, and fails
// rather than capturing a blank or loading frame.
// ===========================================================================

/// One numbered point: a finder, a stable key, and a human label.
class ElementSpec {
  ElementSpec({
    required this.key,
    required this.label,
    required this.finder,
  })  : keyOf = null,
        labelOf = null;

  /// A finder that matches SEVERAL widgets; key and label are derived per match.
  ElementSpec.each({
    required this.keyOf,
    required this.labelOf,
    required this.finder,
  })  : key = '',
        label = '';

  final String key;
  final String label;
  final Finder finder;
  final String Function(int index, Widget widget)? keyOf;
  final String Function(int index, Widget widget)? labelOf;
}

class _Measured {
  _Measured(this.key, this.label, this.rect);

  final String key;
  final String label;
  final Rect rect;
}

/// Mocks the path_provider channel so real drift/sqlite stores can open a
/// database in a temp dir. This is the ONLY platform channel the harness fakes.
void _mockPathProvider(String dir) {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => dir);
}

/// The other channels this harness has to answer. All answer NULL.
void _mockAbsentPlugins() {
  const channels = <String>[
    'plugins.it_nomads.com/flutter_secure_storage',
    'dev.fluttercommunity.plus/connectivity',
    'dev.fluttercommunity.plus/connectivity_status',
  ];
  for (final name in channels) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(name), (call) async => null);
  }
}

/// Pumps until the screen is READY - every [readyFinders] matches and no
/// CircularProgressIndicator is showing - letting real async work (the demo
/// gateway, sqlite) run between frames. Replaces a fixed ~1s wait that
/// captured the light frame while it was still loading. Fails the test on
/// [kReadyTimeout] instead of writing a broken frame.
Future<void> _pumpUntilReady(WidgetTester tester, {String phase = ''}) async {
  final deadline = DateTime.now().add(kReadyTimeout);
  final spinner = find.byType(CircularProgressIndicator);
  var stableFrames = 0;
  while (true) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
    final ready = readyFinders().every((f) => f.evaluate().isNotEmpty) &&
        spinner.evaluate().isEmpty;
    // Two ready frames in a row, so a list that is still filling in (or a
    // spinner about to come back for a second request) is not captured
    // mid-way.
    stableFrames = ready ? stableFrames + 1 : 0;
    if (stableFrames >= 2) break;
    if (DateTime.now().isAfter(deadline)) {
      final missing = readyFinders()
          .where((f) => f.evaluate().isEmpty)
          .map((f) => f.describeMatch(Plurality.zero))
          .toList();
      fail('screen not ready after ${kReadyTimeout.inSeconds}s$phase: '
          '${missing.isEmpty ? '' : 'missing ${missing.join(', ')}; '}'
          '${spinner.evaluate().length} spinner(s) still showing. '
          'Refusing to capture a blank or loading frame.');
    }
  }
  // Let entrance animations finish so nothing is captured half-faded.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Rect, in logical px, of every painted leaf under the boundary: text,
/// images, custom paint, decorated and physical boxes. Offstage subtrees are
/// skipped.
Map<RenderBox, Rect> _paintedLeaves(RenderObject root) {
  final out = <RenderBox, Rect>{};
  void visit(RenderObject o) {
    if (o is RenderOffstage && o.offstage) return;
    // An IndexedStack lays out every tab but paints only the selected one;
    // the hidden tabs must not count as content.
    if (o is RenderIndexedStack) {
      var child = o.firstChild;
      for (var i = 0; child != null; i++) {
        if (i == o.index) visit(child);
        child = o.childAfter(child);
      }
      return;
    }
    if (o is RenderBox &&
        o.attached &&
        o.hasSize &&
        (o is RenderParagraph ||
            o is RenderImage ||
            o is RenderCustomPaint ||
            o is RenderDecoratedBox ||
            o is RenderPhysicalModel ||
            o is RenderPhysicalShape)) {
      final rect = MatrixUtils.transformRect(
          o.getTransformTo(root), Offset.zero & o.size);
      if (rect.width > 0 && rect.height > 0) out[o] = rect;
    }
    o.visitChildren(visit);
  }

  root.visitChildren(visit);
  return out;
}

/// How tall the frame must be to show all of the content and nothing else.
///
/// The screen root (and any background) always fills the probe viewport, so
/// its rect says nothing about the content. Instead the screen is laid out at
/// two probe heights and every painted leaf is compared:
///   * a leaf that did not move is CONTENT (laid out from the top);
///   * a leaf that moved with the viewport bottom by the same amount and kept
///     its size is PINNED to the bottom (tab bar, floating button) and is
///     reserved below the content so it never covers it;
///   * anything else (stretched backgrounds, centred fills) is ignored.
/// Returns null when the content does not fit inside [kProbeHeight].
Future<double?> _contentHeight(
    WidgetTester tester, RenderObject Function() root) async {
  const shrink = 400.0;
  final tall = _paintedLeaves(root());
  _setViewHeight(tester, kProbeHeight - shrink);
  await _pumpUntilReady(tester, phase: ' (second probe)');
  final short = _paintedLeaves(root());
  _setViewHeight(tester, kProbeHeight);
  await _pumpUntilReady(tester, phase: ' (back to probe height)');

  var contentBottom = 0.0;
  var pinnedReserve = 0.0;
  var matched = 0;
  for (final entry in tall.entries) {
    final a = entry.value;
    final b = short[entry.key];
    if (b != null) matched++;
    if (b == null || (a.bottom - b.bottom).abs() < 0.5) {
      if (a.bottom > contentBottom) contentBottom = a.bottom;
    } else if ((a.bottom - b.bottom - shrink).abs() < 0.5 &&
        (a.height - b.height).abs() < 0.5) {
      final reserve = kProbeHeight - a.top;
      if (reserve > pinnedReserve) pinnedReserve = reserve;
    }
  }
  if (matched == 0) {
    throw StateError('the screen rebuilt every render object between the two '
        'probes, so content and viewport-pinned chrome cannot be told apart');
  }
  if (contentBottom <= 0) {
    throw StateError('no painted content found under the screen');
  }
  final height = contentBottom + pinnedReserve + kBottomPadding;
  // ignore: avoid_print
  print('render: content ends at ${contentBottom.toStringAsFixed(1)}, '
      'pinned chrome needs ${pinnedReserve.toStringAsFixed(1)} -> '
      'frame height ${height.toStringAsFixed(1)}');
  if (contentBottom + pinnedReserve >= kProbeHeight - 1) return null;
  return height;
}

void _setViewHeight(WidgetTester tester, double height) {
  tester.view.physicalSize =
      Size(kLogicalWidth * kDevicePixelRatio, height * kDevicePixelRatio);
}

List<_Measured> _measure(WidgetTester tester, List<ElementSpec> specs) {
  final measured = <_Measured>[];
  for (final spec in specs) {
    final elements = spec.finder.evaluate().toList();
    for (var i = 0; i < elements.length; i++) {
      try {
        final widget = elements[i].widget;
        measured.add(_Measured(
          spec.keyOf?.call(i, widget) ?? spec.key,
          spec.labelOf?.call(i, widget) ?? spec.label,
          tester.getRect(spec.finder.at(i)),
        ));
      } catch (_) {
        // Off-stage or unlaid-out matches are skipped rather than failing.
      }
    }
  }

  measured.sort((a, b) => a.rect.top.compareTo(b.rect.top));
  final deduped = <_Measured>[];
  for (final item in measured) {
    final clash = deduped.any((kept) =>
        (kept.rect.top - item.rect.top).abs() < 2 &&
        (kept.rect.height - item.rect.height).abs() < 4);
    if (!clash) deduped.add(item);
  }
  return deduped;
}

/// Renders one variant end to end and writes `out/<name>.png` + `out/<name>.json`.
Future<void> renderVariant(
  WidgetTester tester, {
  required bool dark,
  required String name,
  required String dbDir,
}) async {
  final outDir = Directory('${Directory.current.path}/out')
    ..createSync(recursive: true);

  _mockPathProvider(dbDir);
  _mockAbsentPlugins();

  await tester.runAsync(_loadRealFontsOnce);

  registerExceptionStubs();
  await tester.runAsync(() => primeAppState(dark: dark));
  await tester.runAsync(registerDemoDependencies);
  await tester.runAsync(persistDemoUser);
  await seedDeviceHistory(tester);
  registerScreen();

  tester.view.physicalSize =
      Size(kLogicalWidth * kDevicePixelRatio, kProbeHeight * kDevicePixelRatio);
  tester.view.devicePixelRatio = kDevicePixelRatio;
  addTearDown(tester.view.reset);

  final boundaryKey = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(
    key: boundaryKey,
    child: buildScreen(dark: dark),
  ));
  await _pumpUntilReady(tester, phase: ' ($name)');

  var measured = _measure(tester, elementSpecs());
  expect(measured, isNotEmpty,
      reason: 'no elements matched - check elementSpecs() and the screen the '
          'harness pumps');

  final fitted = await _contentHeight(
      tester, () => boundaryKey.currentContext!.findRenderObject()!);
  final double targetHeight;
  if (fitted == null) {
    targetHeight = kDeviceHeight;
    // ignore: avoid_print
    print('WARNING: $name is taller than the ${kProbeHeight.toInt()} px probe; '
        'capturing one ${kDeviceHeight.toInt()} px phone screen instead.');
  } else {
    targetHeight = fitted.clamp(400.0, kProbeHeight);
  }

  _setViewHeight(tester, targetHeight);
  await _pumpUntilReady(tester, phase: ' ($name, final height)');
  measured = _measure(tester, elementSpecs());

  final blockGlyphs =
      _blockGlyphTexts(boundaryKey.currentContext!.findRenderObject()!);
  if (blockGlyphs.isNotEmpty) {
    fail('${blockGlyphs.length} text(s) drawn in the FlutterTest block font - '
        'register their family in loadRealFonts(): '
        '${blockGlyphs.take(5).join(' | ')}');
  }

  await tester.runAsync(() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: kDevicePixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${outDir.path}/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());

    final sidecar = <String, Object?>{
      'variant': name,
      'logicalWidth': kLogicalWidth,
      'logicalHeight': targetHeight,
      'devicePixelRatio': kDevicePixelRatio,
      // Read by shared-workflows' frame quality gate, which refuses the
      // frame if either count is non-zero.
      'quality': <String, Object?>{
        'spinners': find.byType(CircularProgressIndicator).evaluate().length,
        'blockGlyphTexts': blockGlyphs.length,
      },
      'elements': <Object>[
        for (var i = 0; i < measured.length; i++)
          <String, Object?>{
            'number': i + 1,
            'key': measured[i].key,
            'label': measured[i].label,
            'x': measured[i].rect.left,
            'y': measured[i].rect.top,
            'w': measured[i].rect.width,
            'h': measured[i].rect.height,
          }
      ],
    };
    File('${outDir.path}/$name.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(sidecar));
  });

  // EXPERIMENTAL, opt-in: the same frame as a true vector SVG (real shapes
  // and <text>), next to the PNG. Off in CI until it has been reviewed.
  if (Platform.environment['RENDER_VECTOR'] == '1') {
    final recorder = VectorSvgRecorder(devicePixelRatio: kDevicePixelRatio)
      ..paint(boundaryKey.currentContext!.findRenderObject()!);
    final svg = await tester.runAsync(recorder.finish);
    File('${outDir.path}/$name.vector.svg').writeAsStringSync(svg!);
    // ignore: avoid_print
    print('vector: $name.vector.svg - ${recorder.vectorTexts} text runs, '
        '${recorder.rasterFallbacks} bitmap fallback(s), '
        '${svg.length ~/ 1024} KB'
        '${recorder.warnings.isEmpty ? '' : '; ${recorder.warnings.toSet().join('; ')}'}');
  }
}

/// Texts on screen that are drawn in the FlutterTest/Ahem block font.
///
/// A block glyph advances exactly one em, so a single-line text whose width
/// is (characters x font size) is in the block font: its family was never
/// registered. Returned as `family: text` for the failure message.
List<String> _blockGlyphTexts(RenderObject root) {
  final hits = <String>[];
  void visit(RenderObject o) {
    if (o is RenderOffstage && o.offstage) return;
    if (o is RenderParagraph && o.attached && o.hasSize) {
      final text = o.text.toPlainText(includePlaceholders: false);
      final style = o.text.style;
      final size = style?.fontSize;
      final chars = text.runes.length;
      if (size != null &&
          chars >= 3 &&
          !text.contains('\n') &&
          o.text is TextSpan &&
          ((o.text as TextSpan).children?.isEmpty ?? true)) {
        final width = o.getMaxIntrinsicWidth(double.infinity);
        final em = o.textScaler.scale(size);
        final spacing = (style?.letterSpacing ?? 0) * chars;
        if ((width - spacing - chars * em).abs() < 0.5) {
          hits.add('${style?.fontFamily ?? '(default)'}: "$text"');
        }
      }
    }
    o.visitChildren(visit);
  }

  root.visitChildren(visit);
  return hits;
}

bool _fontsLoaded = false;
Future<void> _loadRealFontsOnce() async {
  if (_fontsLoaded) return;
  await loadRealFonts();
  _fontsLoaded = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = true;

  final dbDir = Directory.systemTemp.createTempSync('render_harness_db').path;

  final suffix = Platform.environment['RENDER_SUFFIX'] ?? '';

  testWidgets('render sticks team home - dark (app default)', (tester) async {
    await renderVariant(tester,
        dark: true, name: 'sticks_team_home_dark$suffix', dbDir: dbDir);
  });

  testWidgets('render sticks team home - light', (tester) async {
    await renderVariant(tester,
        dark: false, name: 'sticks_team_home_light$suffix', dbDir: dbDir);
  });
}
