#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT_BIN:-godot}"
OUTPUT_DIR="${1:-artifacts/screenshots}"
mkdir -p "$OUTPUT_DIR"

capture_scene() {
  local scene="$1"
  local name="$2"
  local pid

  "$GODOT" --path . --resolution 1920x1080 --windowed "$scene" &
  pid=$!
  cleanup() {
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  }
  trap cleanup RETURN

  # Give the renderer and scene scripts time to finish their first frames.
  sleep 4
  import -window root "$OUTPUT_DIR/$name.png"

  # The demo and pixel test both bind F3 to the CRT toggle.
  xdotool key F3
  sleep 1
  import -window root "$OUTPUT_DIR/${name}_crt.png"

  cleanup
  trap - RETURN
}

capture_scene "" "demo"
capture_scene "res://examples/pixel_test/pixel_test.tscn" "pixel-test"
