# Changelog

## 1.2.0

- The in-lesson lane is built. New `LessonAssistantLane` is the agent side of a host's lesson assistant bridge: it asks through `AssistantService.forLesson`, so every question goes to `api.ask_assistant` on the platform gateway with `in_lesson: true`, the lesson's current subtopic as `subtopic_ref` (empty before the first), and the transcript under the lesson session id. `ask()` completes when the answer or the failure has arrived and never throws for a backend failure. lms_sdk 1.46.1's lesson route uses it for real (non-demo) sessions; before, only the demo lane existed, so nothing sent `in_lesson: true`.

## 1.1.0

- In-lesson chat sends `in_lesson`. `AgentFacade.askAssistant` takes `inLesson` and `AgentRepository` always sends it (`true` or `false`) to `api.ask_assistant`. `AssistantService` takes `inLesson` (default `false`, the standalone chat page), and the new `AssistantService.forLesson` factory sets it to `true` for a host's lesson bridge. The backend now fails closed whenever `in_lesson` is true, including a lesson question asked before the first subtopic (no `subtopic_ref`). The `subtopic_ref` check stays for older clients.
- Assistant chat history is now saved per account (claimed in 1.0.4, built now). New `AssistantHistoryStore` saves the question when it is sent and the answer when it arrives, in `assistant_history_table` under the signed-in account. Nothing is saved when nobody is signed in. Reads return only this account's rows (plus unowned pre-scoping rows), so another account never sees the transcript. `AssistantService.loadHistory()` returns it, and the chat page shows it when it opens. The store is local and best effort: it works the same offline and never shows an error.
- `AgentSdkDependencies.register` registers the history store on the shared `AppDatabase`. It also registers the `assets/demo/agent` demo fixtures. The new `api.ask_assistant` fixture lets a demo chat answer through the real repository, and its history fills the same way.

## 1.0.8

- The assistant chat page cancels its stream subscriptions when it closes, and `AssistantService.dispose` no longer closes the chat controllers it was given (they belong to the host's transport); it stops listening and closes only its own error stream.

## 1.0.7

- Icons move to Remixicon (`.rokct/decision_log.md`, "Icon package
  standard"): every Material `Icons.*` is now the matching `Remix.*`
  glyph, and the pubspec pins `remixicon: ^1.4.1`. Icons only.

## 1.0.6

- `AgentRepository.uploadPath` carries a one-line
  `// bypasses gateway: multipart upload` tag, so gateway audits can tell
  this allowed bypass (raw file bytes cannot ride the JSON `{cmd, payload}`
  envelope) from an unintended one. No behaviour change.

## 1.0.5

- The assistant chat page shows a progress line while a reply is pending
  and disables send until it arrives, so one question is in flight at a
  time.
- A message is trimmed before the empty check; whitespace alone is not
  sent.
- The plan gate says why. `api.ask_assistant` now refuses a plan without
  chat with a 403, and the page shows that server line ("Chat isn't
  included in your plan.") in place of the generic "isn't available"
  banner. Every other failure keeps the generic banner, and its detail
  still goes only to telemetry.

## 1.0.4

- `assistant_history_table` is owner-scoped. It gains an `owner` column
  (NOT NULL, defaulting to the empty string) which joins the primary key
  alongside `id`, so two accounts on one device cannot read each other's
  assistant transcripts and an offline id minted from the clock can no
  longer have one account's message silently replace another's. Reads
  filter with base_sdk's `ownerVisible(owner, me)` - the current account's
  rows plus every unowned one - and writes stamp
  `OwnerScope.instance.current`.
- Scoping is a VISIBILITY rule, never a deletion: signing out writes
  nothing and removes nothing. The departing account's history stays on
  disk, invisible to the next account, and comes back in full when that
  account signs in again.
- Migration version 21 (shared fleetwide namespace, declared in
  `manifest.json`). The step rebuilds the table the long way round -
  rename aside, recreate, copy the shared columns, drop - because SQLite
  cannot alter a primary key in place. Rows already on the device take the
  `''` default and stay visible to everyone, so the upgrade is invisible
  to the account already using the app. `ensureAgentOwnerScopeColumns` is
  idempotent and self-checking, the same shape as base_sdk's
  `ensureOwnerScopeColumns`.
- `assistant_cache_table` is deliberately NOT scoped: a question and its
  answer are content, not a record of who asked.
- Requires base_sdk 1.67.0 (`OwnerScope`, `kUnownedOwner`, `ownerVisible`).

## 1.0.3

Fix-wave 2026-09-02 (Dart SDK audit, agent items).

- A2: `AgentRepository.submitHomework` no longer posts multipart to
  `/api/v1/method/agent.api.submit_homework` — an alias no manifest ever
  declared, so every submission 404'd. Photos now go up one by one through
  core's upload door (`/api/v1/method/rcore.api.upload.upload_file`,
  multipart, private), and only the returned `file_url`s ride the JSON
  gateway call to `api.lms.submit_homework_question` (lms's
  `rlms.api.homework.submit_homework_question`). The facade gains an
  optional `questionText`; a photos-only submission is labelled with the
  lesson id because the server refuses an empty question. The result is
  the new question's id. `AgentRepository.uploadAppPrefix` is the boot-time
  override point for the served shell app (mirrors lms_sdk).
- A3: deleted the commented-out `AiTranslationProvider` adapter example
  in `agent_di.dart` that targeted the Laravel-era
  `/api/v1/dashboard/seller/ai-translations` path (never served by the
  Frappe router). The `AiTranslationProvider` interface itself is
  unchanged.
- New `test/agent_repository_test.dart` pins the two-step submission
  (request paths, multipart field names, gateway `cmd` + payload keys,
  failure posture) with a scripted Dio adapter; `flutter_test` added to
  dev_dependencies.
