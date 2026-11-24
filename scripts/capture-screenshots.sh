#!/usr/bin/env bash
set -euo pipefail

GODOT="${GODOT_BIN:-godot}"
OUTPUT_DIR="${1:-artifacts/screenshots}"
mkdir -p "$OUTPUT_DIR"

capture_scene() {
  local scene="$1"
  local name="$2"
  local pid
  local window_id

  if [[ -n "$scene" ]]; then
    "$GODOT" --path . --audio-driver Dummy --resolution 1920x1080 --windowed "$scene" > "$OUTPUT_DIR/$name.log" 2>&1 &
  else
    "$GODOT" --path . --audio-driver Dummy --resolution 1920x1080 --windowed > "$OUTPUT_DIR/$name.log" 2>&1 &
  fi
  pid=$!

  # Wait for the actual Godot window, not just for the process to start.
  for attempt in $(seq 1 20); do
    window_id="$(xdotool search --onlyvisible --pid "$pid" 2>/dev/null | head -n 1 || true)"
    [[ -n "$window_id" ]] && break
    sleep 1
  done

  if [[ -z "$window_id" ]]; then
    cat "$OUTPUT_DIR/$name.log"
    echo "Godot window was not created for $name." >&2
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    return 1
  fi

  sleep 3
  if grep -E "SCRIPT ERROR:|ERROR: Failed to load script" "$OUTPUT_DIR/$name.log"; then
    cat "$OUTPUT_DIR/$name.log"
    echo "Godot reported a script loading error for $name." >&2
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    return 1
  fi

  import -window "$window_id" "$OUTPUT_DIR/$name.png"
  xdotool key --window "$window_id" --clearmodifiers F3
  sleep 1
  import -window "$window_id" "$OUTPUT_DIR/${name}_crt.png"

  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  cat "$OUTPUT_DIR/$name.log"
}

capture_scene "" "demo"
capture_scene "res://examples/pixel_test/pixel_test.tscn" "pixel-test"
