#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
UPBGE_DIR="${UPBGE_DIR:-${ROOT_DIR}/third_party/upbge}"
JOBS="${JOBS:-2}"
SKIP_APT="${SKIP_APT:-0}"
USE_SOURCE_DEPS="${USE_SOURCE_DEPS:-auto}"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script is intended for Linux (Raspberry Pi OS)."
  exit 1
fi

if [[ "$(uname -m)" != "aarch64" ]]; then
  echo "Warning: expected aarch64 for Raspberry Pi 5, detected $(uname -m)."
fi

install_packages() {
  if [[ "${SKIP_APT}" == "1" ]]; then
    echo "Skipping apt package installation (SKIP_APT=1)."
    return
  fi

  if ! command -v apt >/dev/null 2>&1; then
    echo "apt not found. Install dependencies manually for your distro."
    return
  fi

  if [[ "$(id -u)" -eq 0 ]]; then
    APT_CMD=(apt)
  elif command -v sudo >/dev/null 2>&1; then
    APT_CMD=(sudo apt)
  else
    echo "Need root privileges or sudo for apt install."
    exit 1
  fi

  echo "Installing build dependencies with apt..."
  "${APT_CMD[@]}" update
  "${APT_CMD[@]}" install -y \
    build-essential git git-lfs subversion cmake ninja-build pkg-config \
    python3 python3-dev python3-venv \
    libx11-dev libx11-xcb-dev libxxf86vm-dev libxcursor-dev libxi-dev libxrandr-dev libxinerama-dev \
    libxcb-randr0-dev libpixman-1-dev libdrm-dev libudev-dev libinput-dev libcairo2-dev libpango1.0-dev libgles2-mesa-dev libgles-dev libgbm-dev liblcms2-dev libelf-dev libunwind-dev \
    libegl-dev libwayland-dev wayland-protocols libxkbcommon-dev libdbus-1-dev linux-libc-dev
}

clone_upbge() {
  if [[ -d "${UPBGE_DIR}/.git" ]]; then
    echo "UPBGE source already exists at ${UPBGE_DIR}."
    return
  fi

  mkdir -p "$(dirname "${UPBGE_DIR}")"
  echo "Cloning UPBGE source..."
  GIT_LFS_SKIP_SMUDGE=1 git clone https://github.com/UPBGE/upbge.git "${UPBGE_DIR}"
}

patch_upbge_for_rpi5() {
  local osl_cmake
  local root_cmake
  osl_cmake="${UPBGE_DIR}/build_files/build_environment/cmake/osl.cmake"
  root_cmake="${UPBGE_DIR}/CMakeLists.txt"
  if [[ ! -f "${osl_cmake}" ]]; then
    return
  fi

  # UPBGE enables OSL OptiX on Linux by default, but RPi5 has no CUDA/OptiX stack.
  if grep -q 'if(NOT (APPLE OR BLENDER_PLATFORM_WINDOWS_ARM))' "${osl_cmake}"; then
    echo "Patching OSL dependency config for ARM64 (disable OptiX requirement)..."
    sed -i.bak \
      's/if(NOT (APPLE OR BLENDER_PLATFORM_WINDOWS_ARM))/if(NOT (APPLE OR BLENDER_PLATFORM_WINDOWS_ARM OR BLENDER_PLATFORM_ARM))/g' \
      "${osl_cmake}"
  fi

  if ! grep -q 'elseif(BLENDER_PLATFORM_ARM)' "${osl_cmake}"; then
    echo "Patching OSL to force OptiX OFF on ARM64..."
    sed -i.bak \
      '/-DCUDA_TOOLKIT_ROOT_DIR=\${CUDAToolkit_ROOT}/a\
  )\
elseif(BLENDER_PLATFORM_ARM)\
  list(APPEND OSL_EXTRA_ARGS\
    -DOSL_USE_OPTIX=OFF' \
      "${osl_cmake}"
  fi

  if [[ -f "${root_cmake}" ]] && grep -q 'VERSION_LESS "14.0.0"' "${root_cmake}"; then
    echo "Patching Blender GCC minimum version check for ARM64 (14 -> 13)..."
    sed -i.bak \
      's/VERSION_LESS "14.0.0"/VERSION_LESS "13.0.0"/g; s/minimum supported version of GCC is 14.0.0/minimum supported version of GCC is 13.0.0/g' \
      "${root_cmake}"
  fi
}

build_upbge() {
  cd "${UPBGE_DIR}"
  git lfs install --force
  patch_upbge_for_rpi5

  local arch
  arch="$(uname -m)"

  if [[ "${USE_SOURCE_DEPS}" == "1" || ("${USE_SOURCE_DEPS}" == "auto" && ("${arch}" == "aarch64" || "${arch}" == "arm64")) ]]; then
    echo "Using source-built dependencies for ${arch} (no precompiled UPBGE libs on Linux ARM64)..."
    make update_code
    if [[ "${arch}" == "aarch64" || "${arch}" == "arm64" ]]; then
      local deps_build_dir deps_install_dir
      deps_build_dir="$(dirname "${UPBGE_DIR}")/build_linux/deps_arm64"
      deps_install_dir="${UPBGE_DIR}/lib/linux_arm64"
      echo "Configuring deps with BLENDER_PLATFORM_ARM=ON..."
      cmake -H"${UPBGE_DIR}/build_files/build_environment" \
        -B"${deps_build_dir}" \
        -DHARVEST_TARGET="${deps_install_dir}" \
        -DBLENDER_PLATFORM_ARM=ON
      echo "Building deps target 'install'..."
      cmake --build "${deps_build_dir}" --parallel "${JOBS}" --target install
    else
      make -j"${JOBS}" deps
    fi
  else
    echo "Running make update (downloads dependencies/submodules)..."
    make update
  fi

  if [[ -d scripts/addons_core ]]; then
    echo "Updating addons_core submodule..."
    (
      cd scripts/addons_core
      GIT_LFS_SKIP_SMUDGE=1 git submodule update --init --recursive --remote . || true
      if [[ -d bge_netlogic ]]; then
        cd bge_netlogic
        GIT_LFS_SKIP_SMUDGE=1 git checkout master || true
        GIT_LFS_SKIP_SMUDGE=1 git pull --rebase origin master || true
      fi
    )
  fi

  echo "Building UPBGE with ${JOBS} jobs..."
  if [[ "${arch}" == "aarch64" || "${arch}" == "arm64" ]]; then
    local cmake_libdir
    cmake_libdir="${UPBGE_DIR}/lib/linux_arm64"
    make -j"${JOBS}" BUILD_CMAKE_ARGS="-DLIBDIR=${cmake_libdir} -DWITH_LIBS_PRECOMPILED=ON -DWITH_USD=OFF -DWITH_HYDRA=OFF"
  else
    make -j"${JOBS}"
  fi
}

main() {
  install_packages
  clone_upbge
  build_upbge

  cat <<MSG

Setup complete.

Built UPBGE under:
  ${UPBGE_DIR}

Launch FlowState with:
  ${ROOT_DIR}/scripts/run_rpi5.sh

MSG
}

main "$@"
