# sticks

Sticks: AI employees you manage from your phone (Flutter app composing agent_sdk with the sticks flavor).

Spawned by [RokctAI Factory](https://github.com/rokctai/factory) from <https://github.com/RokctAI/factory/issues/44>.

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
