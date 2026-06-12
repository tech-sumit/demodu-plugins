#!/usr/bin/env bash
# demodu-recorder — "video ready" hook.
#
# Fires as a Claude Code PostToolUse hook matching the MCP tool
# `mcp__demodu__demodu_recording_playback`. That tool only yields a playback
# URL once the render is done, so its success IS the "video ready" event.
#
# Reads the hook payload JSON on stdin, pulls out the recording id and the
# playback URL, downloads the MP4 next to the user's project, and pops a macOS
# notification. ALWAYS exits 0 — a download hiccup must never fail the agent's
# tool call.
set -uo pipefail

log() { printf '[demodu-recorder] %s\n' "$*" >&2; }

payload="$(cat)"

# Prefer jq when available; fall back to grep so the hook works without jq.
extract() { # $1 = jq filter, $2 = grep -Eo fallback regex
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null
  else
    printf '%s' "$payload" | grep -Eo "$2" | head -1
  fi
}

cwd="$(extract '.cwd' '"cwd"[[:space:]]*:[[:space:]]*"[^"]+"' | sed -E 's/.*"cwd"[^"]*"([^"]+)".*/\1/')"
[ -n "${cwd:-}" ] && [ -d "$cwd" ] || cwd="$PWD"

# recordingId from the tool input (the arg the agent passed).
rec="$(extract '.tool_input.recordingId // .tool_input.id' '"(recordingId|id)"[[:space:]]*:[[:space:]]*"[^"]+"' | sed -E 's/.*"[^"]+"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
[ -n "${rec:-}" ] || rec="recording-$(date +%s 2>/dev/null || echo latest)"

# Playback URL: grab the first http(s) URL anywhere in the tool_response blob.
# Handles a parsed result OR the raw MCP {content:[{type:'text',text:"{…url…}"}]}
# shape — we don't depend on the exact JSON, just the URL inside it.
url="$(printf '%s' "$payload" | grep -Eo 'https?://[^"[:space:]\\]+' | grep -Ei '\.mp4|playback|recordings|r2|amazonaws|cloudflarestorage' | head -1)"
[ -n "${url:-}" ] || url="$(printf '%s' "$payload" | grep -Eo 'https?://[^"[:space:]\\]+' | head -1)"

if [ -z "${url:-}" ]; then
  log "no playback URL found in tool result — nothing to download"
  exit 0
fi

out_dir="$cwd/demodu-recordings"
mkdir -p "$out_dir" 2>/dev/null || out_dir="$PWD"
out="$out_dir/${rec}.mp4"

log "downloading recording $rec → $out"
if ! curl -fL --retry 1 --connect-timeout 15 -o "$out" "$url" 2>/dev/null; then
  log "download failed (url: ${url%%\?*}). Re-run demodu_recording_playback and curl it manually."
  exit 0
fi

size="$(wc -c < "$out" 2>/dev/null | tr -d ' ')"
log "saved ${size:-?} bytes → $out"

# macOS notification + chime (best-effort; silent no-op elsewhere).
if command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"Saved $rec.mp4\" with title \"demodu — video ready\" sound name \"Glass\"" >/dev/null 2>&1 || true
fi
command -v afplay >/dev/null 2>&1 && afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1 &

exit 0
