#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT_BIN:-godot}"
OUTPUT_DIR="${1:-artifacts/screenshots}"
mkdir -p "$OUTPUT_DIR"

capture_scene() {
  local scene="$1"
  local name="$2"
  local pid

  if [[ -n "$scene" ]]; then
    "$GODOT" --path . --resolution 1920x1080 --windowed "$scene" &
  else
    "$GODOT" --path . --resolution 1920x1080 --windowed &
  fi
  pid=$!

  sleep 4
  import -window root "$OUTPUT_DIR/$name.png"
  xdotool key --clearmodifiers F3
  sleep 1
  import -window root "$OUTPUT_DIR/${name}_crt.png"

  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
}

capture_scene "" "demo"
capture_scene "res://examples/pixel_test/pixel_test.tscn" "pixel-test"
