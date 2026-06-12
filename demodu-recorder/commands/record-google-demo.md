---
description: Record the demodu google test script via the demodu MCP server and auto-download the video when ready.
argument-hint: "[optional: project name to record in]"
allowed-tools: mcp__demodu__demodu_list_projects, mcp__demodu__demodu_list_scripts, mcp__demodu__demodu_create_script, mcp__demodu__demodu_validate_script, mcp__demodu__demodu_start_recording, mcp__demodu__demodu_recording_status, mcp__demodu__demodu_recording_playback, Read
---

# Record the google demo

Drive the demodu MCP server (`demodu`) to record the bundled google test script
and download the result. Follow these steps exactly; report progress concisely.

The bundled scene-DSL lives at `${CLAUDE_PLUGIN_ROOT}/scripts/google-test-script.json`.
Read that file when you need its JSON.

## Steps

1. **Pick the project.** Call `demodu_list_projects`. Use the project whose name
   matches `$ARGUMENTS` if given, else the first project. Keep its `id`.

2. **Ensure the google script exists (idempotent).**
   - `demodu_list_scripts(projectId)`. If a script whose name contains "Google"
     (case-insensitive) already exists, reuse its `id`.
   - Otherwise read `${CLAUDE_PLUGIN_ROOT}/scripts/google-test-script.json`,
     optionally `demodu_validate_script(scriptJson)` to confirm it's valid, then
     `demodu_create_script(projectId, name, scriptJson)` and keep the new `id`.

3. **Start the recording.** `demodu_start_recording(scriptId)`. Keep the
   returned `recordingId`. Tell the user the recording has started and that the
   google script pauses twice for manual take-control (captcha / pressing Enter)
   in the studio live view.

4. **Poll until done.** Loop `demodu_recording_status(recordingId)` roughly every
   10 seconds (use a short wait between calls). Stop when status is `done` or
   `failed` (give up after ~5 minutes of polling).
   - On `awaiting_human`: tell the user to open the studio live view, take
     control of the mirror, complete the captcha / press Enter, and click Resume
     — then keep polling.
   - On `failed`: report the recorder's error message and STOP. Do not continue.

5. **Fetch the video.** Once `done`, call `demodu_recording_playback(recordingId)`.
   This returns the playback URL — and the plugin's `PostToolUse` hook fires
   automatically here, downloading the MP4 to `./demodu-recordings/<id>.mp4` and
   popping a desktop notification.

6. **Report.** Tell the user the recording is done and the video was saved to
   `./demodu-recordings/<recordingId>.mp4`. If the hook couldn't download it
   (no file appeared), share the playback URL so they can grab it manually.

Keep the user informed at each step; don't dump raw tool JSON.
