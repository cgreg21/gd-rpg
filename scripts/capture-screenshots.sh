#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT_BIN:-godot}"
OUTPUT_DIR="${1:-artifacts/screenshots}"
mkdir -p "$OUTPUT_DIR"

capture_scene() {
  local scene="$1"
  local name="$2"
  local crt="$3"
  local pid
  local window_id
  local suffix="$name"

  if [[ "$crt" == "1" ]]; then
    suffix="${name}_crt"
  fi

  if [[ -n "$scene" ]]; then
    GD_RPG_SCREENSHOT_CRT="$crt" "$GODOT" --path . --audio-driver Dummy --resolution 1920x1080 --windowed "$scene" > "$OUTPUT_DIR/$suffix.log" 2>&1 &
  else
    GD_RPG_SCREENSHOT_CRT="$crt" "$GODOT" --path . --audio-driver Dummy --resolution 1920x1080 --windowed > "$OUTPUT_DIR/$suffix.log" 2>&1 &
  fi
  pid=$!

  for attempt in $(seq 1 20); do
    window_id="$(xdotool search --onlyvisible --pid "$pid" 2>/dev/null | head -n 1 || true)"
    [[ -n "$window_id" ]] && break
    sleep 1
  done

  if [[ -z "$window_id" ]]; then
    cat "$OUTPUT_DIR/$suffix.log"
    echo "Godot window was not created for $suffix." >&2
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    return 1
  fi

  sleep 3
  if grep -E "SCRIPT ERROR:|ERROR: Failed to load script|SHADER ERROR:|Shader compilation failed" "$OUTPUT_DIR/$suffix.log"; then
    cat "$OUTPUT_DIR/$suffix.log"
    echo "Godot reported a script or shader error for $suffix." >&2
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    return 1
  fi

  import -window "$window_id" "$OUTPUT_DIR/$suffix.png"
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  cat "$OUTPUT_DIR/$suffix.log"
}

for crt in 0 1; do
  capture_scene "" "demo" "$crt"
  capture_scene "res://examples/pixel_test/pixel_test.tscn" "pixel-test" "$crt"
done
