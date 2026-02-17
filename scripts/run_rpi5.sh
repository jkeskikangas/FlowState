#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
UPBGE_DIR="${UPBGE_DIR:-${ROOT_DIR}/third_party/upbge}"

DEFAULT_BIN="${UPBGE_DIR}/build_linux/bin/blender"
UPBGE_BIN="${UPBGE_BIN:-${DEFAULT_BIN}}"

if [[ ! -x "${UPBGE_BIN}" ]]; then
  echo "UPBGE binary not found: ${UPBGE_BIN}"
  echo "Run scripts/setup_rpi5.sh first, or set UPBGE_BIN to your blender executable."
  exit 1
fi

export SDL_GAMECONTROLLERCONFIG_FILE="${ROOT_DIR}/gamecontrollerdb.txt"

cd "${ROOT_DIR}"
exec "${UPBGE_BIN}" "${ROOT_DIR}/game.blend"
