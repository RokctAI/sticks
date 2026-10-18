# sticks — accepted brief

> Copied verbatim from https://github.com/RokctAI/factory/issues/44 at spawn time. Do not edit: this is the
> record of what was accepted. Decisions taken while building belong in
> `.rokct/decision_log.md`.

**One line:** Sticks: AI employees you manage from your phone (Flutter app composing agent_sdk with the sticks flavor).

## Rationale

Ray asked for the Sticks app repo on 2026-10-18. It is separate from RokctApp because the app_type flavor is fixed at compose time. It composes `core/utils/flutter/composer/sticks.json` (The-Rokct-Protocol PR #495: agent_sdk as home SDK, plus base, auth, users, comms, telemetry) with `.rokct/config/app_type` = `sticks`. Screens and demo fixtures live in agent/agent/dart (agent PR #519); the call contract is v0.6. Done = the repo composes and builds with demo data first; the backend (`api.sticks.*`) comes later.
