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
| **Auth Reset Password** | **Sticks Team** | **Sticks Stick** |
| ![Auth Reset Password][s04] | ![Sticks Team][s05] | ![Sticks Stick][s06] |
| **Sticks Task** | | |
| ![Sticks Task][s07] | | |

The full tour lives in the [feature guide](marketing/tour/feature-guide.md),
with walkthrough videos alongside it in [`marketing/tour/`](marketing/tour).

[s01]: marketing/tour/store/01-welcome.png
[s02]: marketing/tour/store/02-auth_login.png
[s03]: marketing/tour/store/03-auth_register.png
[s04]: marketing/tour/store/04-auth_reset_password.png
[s05]: marketing/tour/store/05-sticks_team.png
[s06]: marketing/tour/store/06-sticks_stick.png
[s07]: marketing/tour/store/07-sticks_task.png
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
