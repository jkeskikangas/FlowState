# FlowState
This is the repository for the Flow State FPV drone racing simulator 


## Simulator Philosophy

This simulator is a true FPV Drone Racing simulator. The goal is to make it look and feel as similar to a standard racing drone as possible. As such, the goal is *not* to make the most HD/GoPro-esque visuals. Instead the focus is on simulating what pilots see through the goggles, static and all! Here are some of the founding principles of this sim for contributors' consideration. 
- Flight feel is #1 priority
  - This means lowest (realistic) possible input latency
  - Option for typical FPV aspect ratio, and resolutions
- Use as a practice tool
  - Lap times should be similar for most pilots/setups/tracks
  - Editable maps with commonly used track elements
- Visual disturbances similar to those found at an FPV racing event
  - realistic video static/interference
- Competitive
  - The sim does not provide significant advantages to those with high end gaming rigs
  - The "sim quads" could be flown "against" real quads, and yield a fair competition
- Field friendly
  - Should be usable with or without internet connection
  - Should function well on adequately powerful laptops


## Contributing

This project uses UPBGE as its game engine. If you would like to contribute, please follow these steps...
1. run ```git clone https://github.com/skyfpv/FlowState.git```, or download from GitHub webpage
2. Install UPBGE from https://github.com/UPBGE/blender
3. In order for you radio to work in the internal player, place a copy of gamecontrollerdb.txt in ```YOUR_UPBGE_FOLDER/2.79/datafiles/gamecontroller```
4. Open game.blend

## My Controller Doesn't work!!!
If under settings>controller you don't see stick movement from the radio you've connected, please follow this tutorial (https://www.youtube.com/watch?v=FDRx-TblE64&feature=youtu.be). Then create a github issue stating the controller or dongle you are trying to use, and the controller mapping text you got from AntiMicro. Please remember that if all else fails, you can connect your BetaFlight flight controller and reciever to the computer and use it as the joystick input as seen here (https://www.youtube.com/watch?v=wuobzowLfj0).

## Raspberry Pi 5 Setup (Linux ARM64)

UPBGE's latest release currently does not include a Linux ARM64 binary, so Raspberry Pi 5 uses a source build.

1. Use a 64-bit Raspberry Pi OS install (`uname -m` should be `aarch64`).
2. From the project root, run:
   ```bash
   ./scripts/setup_rpi5.sh
   ```
3. Start FlowState:
   ```bash
   ./scripts/run_rpi5.sh
   ```

### Notes

- `scripts/setup_rpi5.sh` installs required apt packages, clones UPBGE into `third_party/upbge`, then builds source dependencies for ARM64 with CMake into `third_party/upbge/lib/linux_arm64` before building UPBGE.
- `scripts/run_rpi5.sh` launches `game.blend` and automatically points SDL to `gamecontrollerdb.txt`.
- Current ARM build output binary is:
  ```bash
  third_party/build_linux/bin/blender
  ```
- If your UPBGE binary lives in a different path, set `UPBGE_BIN` before launching:
  ```bash
  UPBGE_BIN=/path/to/blender ./scripts/run_rpi5.sh
  ```
  For the current build output:
  ```bash
  UPBGE_BIN=third_party/build_linux/bin/blender ./scripts/run_rpi5.sh
  ```

### Dockerized ARM64 Build (Cross-Host Friendly)

If you want to build from a non-Pi machine, use Docker Buildx:

```bash
./scripts/build_rpi5_docker.sh
```

This builds an ARM64 Ubuntu image (`docker/Dockerfile.rpi5-build`) and runs `scripts/setup_rpi5.sh` inside it with `SKIP_APT=1` and `USE_SOURCE_DEPS=1`.

After a successful container build, use:

```bash
UPBGE_BIN=third_party/build_linux/bin/blender ./scripts/run_rpi5.sh
```

Useful overrides:

```bash
PLATFORM=linux/arm64 JOBS=8 IMAGE_NAME=flowstate-rpi5-builder:latest ./scripts/build_rpi5_docker.sh
```
