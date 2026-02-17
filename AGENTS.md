# AGENTS.md
<!-- agents-md-version: 1 -->

## CRITICAL

- MUST: Build/update engine dependencies with `./scripts/setup_rpi5.sh` (host) or `./scripts/build_rpi5_docker.sh` (container).
- MUST: Run `python3 -m compileall scripts` before commit.
- MUST: Run `./scripts/run_rpi5.sh` smoke test before PR.
- MUST: Use `./scripts/setup_rpi5.sh` to manage UPBGE deps and build flags; do not hand-edit third-party build trees.
- NEVER: Force push (`git push --force`, `git push -f`) to shared branches.
- NEVER: If commit hooks are configured in your environment, do not bypass them with `--no-verify`.
- NEVER: Edit generated build output in `third_party/build_linux/`.
- PREFER: Built-in tools for simple file reads/edits; use `rg` for repo-wide file/text search.
- ON FAIL: Read full error output first, then verify Linux ARM64 prerequisites and paths in Env.
- ON FAIL (lint): Fix reported syntax/import issues, then re-run `python3 -m compileall scripts`.
- ON FAIL (test): Confirm `UPBGE_BIN` resolves and run `./scripts/setup_rpi5.sh` again.

## Domain & Context

- Goal: FPV drone racing simulator with realistic racing feel and low-latency gameplay using UPBGE.
- Type: Application
- License: GPL-3.0-only
- Key Terms:
  - `UPBGE`: Blender Game Engine fork used to run `game.blend`.
  - `FlowState`: Runtime/game logic in `scripts/` plus `.blend` assets.
  - `Raspberry Pi 5`: Linux ARM64 target platform for local and Dockerized builds.

## Execution Context

- Run on: Hybrid
- Prefix: `N/A`
- Deploys to: Local runtime (`game.blend` launched by UPBGE binary)

## Commands

```bash
# install
./scripts/setup_rpi5.sh                               # ON FAIL: ensure Linux ARM64 + apt availability, then retry with JOBS=2
# install:docker
./scripts/build_rpi5_docker.sh                        # ON FAIL: verify Docker/buildx availability and rerun with PLATFORM=linux/arm64
# lint
python3 -m compileall scripts                         # ON FAIL: fix reported file, then re-run this command
# test:smoke
./scripts/run_rpi5.sh                                 # ON FAIL: set UPBGE_BIN or rebuild with ./scripts/setup_rpi5.sh
# package:windows
./build.sh                                            # ON FAIL: verify Windows artifacts exist (game.exe, ghosts/, 2.79/, Steam DLLs), then re-run
```

## Structure

```text
docker/                 # ARM64 build image
fonts/                  # in-game font assets
maps/                   # race maps and layouts
scripts/                # gameplay and UI logic
scripts/components/     # UPBGE python components
scripts/abstract/       # core state abstractions
sounds/                 # audio assets
steamworks/             # Steam integration files
textures/               # texture assets
third_party/            # external source/build trees (generated -- do not edit)
```

- `third_party/upbge/` is a script-managed source checkout; do not hand-edit unless explicitly requested.
- `third_party/build_linux/` is generated build output; never edit manually.

## Patterns

- **Module:** Python import-based modules (single-file scripts + package-style dirs)
- **Async:** synchronous loop/event style (no asyncio); use sync patterns for new code
- **Naming:** mixed legacy naming; prefer `snake_case.py` for new files, `snake_case` functions, `PascalCase` classes
- UPBGE/BGE scripts access global game state through `bge.logic` (`logic.flowState`) and scene/controller objects.

## Search

- Semantic: `rg -n "flowState|RaceState|TrackState" scripts` -- game-state queries. Exact: `rg -n "<pattern>" scripts` -- regex text search. Files: `rg --files scripts`.

## Testing Strategy

- Runner: No dedicated automated test framework detected
- Separation: Static check plus runtime smoke test
- Coverage: No threshold
- Conventions: Compile scripts (`python3 -m compileall scripts`) and launch simulator (`./scripts/run_rpi5.sh`) before merge

## CI

- Runs: No CI workflows detected in `.github/workflows/`
- Required checks: local `python3 -m compileall scripts` and `./scripts/run_rpi5.sh` smoke test
- Artifacts: none configured

## Security

- NEVER read/write: `.env`, `*.key`, `*.pem`, credential/token files
- NEVER log/commit: secrets, private keys, tokens
- Secrets via: local environment and external secret stores (not in repo)
- CI secrets: not detected in this repository

## Env

- Linux: ARM64 (`aarch64`) required for native Pi build
- Docker: buildx + ARM64 platform support for cross-host build
- Python: Python 3 required (`python3` used by setup and lint workflow)
- Host baseline: validated with Ubuntu 24.04 ARM64 builder image (`docker/Dockerfile.rpi5-build`)

```bash
# Required vars
UPBGE_DIR=path to UPBGE source tree (default: third_party/upbge)
UPBGE_BIN=path to blender executable used by scripts/run_rpi5.sh
JOBS=parallel build jobs (default 2)
SKIP_APT=1 to skip apt install step in setup script
USE_SOURCE_DEPS=1 to force source dependency build on ARM
```

## Git

- Branch: use `feat/<topic>` or `fix/<topic>` for new work; `master` currently tracks `wild-fpv/master`
- Commit: prefer `feat: ...`, `fix: ...`, `chore: ...` with imperative summary
- Hooks: no repository-managed hook config detected (`.pre-commit-config.*` / `.husky/` absent)
- PR: include Raspberry Pi build/smoke-test result and the exact command(s) run

## Tool Preferences

| Task | Prefer | Avoid |
|------|--------|-------|
| Find files | `rg --files` | `find` for broad scans |
| Find text | `rg -n` | `grep -R` |
| Build on Pi | `./scripts/setup_rpi5.sh` | ad-hoc manual CMake/Make sequences |
| Cross-host ARM build | `./scripts/build_rpi5_docker.sh` | custom one-off Docker commands |
