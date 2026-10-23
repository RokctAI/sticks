# sticks

Sticks: AI employees you manage from your phone (Flutter app composing agent_sdk with the sticks flavor).

Spawned by [RokctAI Factory](https://github.com/rokctai/factory) from <https://github.com/RokctAI/factory/issues/44>.

<!-- @generated-tour-gallery-start -->
## App tour

Styled stills from the committed guided tour - regenerated on every
tour run, so new screens appear here automatically.

| Welcome | Auth Login | Auth Register |
| :---: | :---: | :---: |
| ![Welcome][s01] | ![Auth Login][s02] | ![Auth Register][s03] |
| **Auth Reset Password** | **Sticks Team** | **Sticks Tasks** |
| ![Auth Reset Password][s04] | ![Sticks Team][s05] | ![Sticks Tasks][s06] |
| **Sticks Stick** | **Sticks Task** | **Sticks Ask** |
| ![Sticks Stick][s07] | ![Sticks Task][s08] | ![Sticks Ask][s09] |
| **Sticks Give** | **Sticks Profile** | **Sticks Hire** |
| ![Sticks Give][s10] | ![Sticks Profile][s11] | ![Sticks Hire][s12] |
| **Sticks Setup** | **Sticks Inbox** | **Sticks Calls** |
| ![Sticks Setup][s13] | ![Sticks Inbox][s14] | ![Sticks Calls][s15] |
| **Sticks Talk** | **Sticks Report** | **Sticks Settings** |
| ![Sticks Talk][s16] | ![Sticks Report][s17] | ![Sticks Settings][s18] |
| **Sticks Lock** | | |
| ![Sticks Lock][s19] | | |

The full tour lives in the [feature guide](marketing/tour/feature-guide.md),
with walkthrough videos alongside it in [`marketing/tour/`](marketing/tour).

[s01]: marketing/tour/store/01-welcome.png
[s02]: marketing/tour/store/02-auth_login.png
[s03]: marketing/tour/store/03-auth_register.png
[s04]: marketing/tour/store/04-auth_reset_password.png
[s05]: marketing/tour/store/05-sticks_team.png
[s06]: marketing/tour/store/06-sticks_tasks.png
[s07]: marketing/tour/store/07-sticks_stick.png
[s08]: marketing/tour/store/08-sticks_task.png
[s09]: marketing/tour/store/09-sticks_ask.png
[s10]: marketing/tour/store/10-sticks_give.png
[s11]: marketing/tour/store/11-sticks_profile.png
[s12]: marketing/tour/store/12-sticks_hire.png
[s13]: marketing/tour/store/13-sticks_setup.png
[s14]: marketing/tour/store/14-sticks_inbox.png
[s15]: marketing/tour/store/15-sticks_calls.png
[s16]: marketing/tour/store/16-sticks_talk.png
[s17]: marketing/tour/store/17-sticks_report.png
[s18]: marketing/tour/store/18-sticks_settings.png
[s19]: marketing/tour/store/19-sticks_lock.png
<!-- @generated-tour-gallery-end -->

<!-- @generated-render-strip-start -->
## Design review strip

[render-strip.html](marketing/tour/render-strip.html)
is one self-contained page of this app's real screens - rendered
headlessly from the code in this commit, before the tour's emulator
legs ran, with every point numbered from the widget's own measured
rectangle.

GitHub serves a committed .html file as source, so open it from a
local checkout (or download the raw file) to read the page.
<!-- @generated-render-strip-end -->

## Status

Nothing is built yet. The full brief lives in [docs/spec.md](docs/spec.md); the
build instructions for the agent live in [AGENTS.md](AGENTS.md).

## Getting started

```bash
bash .rokct/bootstrap.sh   # installs the Rokct agent protocol into this repo
```

<!-- @generated-recompose-start -->
## Recomposing this app

`lib/` is fully installer-generated and disposable - it is safe to delete
and is gitignored. Anything app-specific lives in tracked manifests
(`app_routes`, or `host_routes` in `composer.json`), never in `lib/` itself.

To regenerate it:

```sh
python3 .rokct/initiate.py   # provisions the composer under .rokct/skills/
python3 .rokct/skills/.rok/flutter/scripts/compose.py
```

Session cleanup (`python3 .rokct/end_protocol.py`) wipes the provisioned
tools again.
<!-- @generated-recompose-end -->
