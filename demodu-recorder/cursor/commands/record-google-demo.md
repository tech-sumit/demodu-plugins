# Record the google demo (demodu)

Drive the `demodu` MCP server to record the google test script and download the
video. Cursor has no hook system, so **you** (the agent) do the download inline
via the terminal at the end.

The bundled scene-DSL is at `scripts/google-test-script.json` inside this plugin
(or paste the JSON from the demodu-recorder plugin's `scripts/` folder).

## Steps

1. `demodu_list_projects` → pick the first project (or one the user names); keep `id`.
2. `demodu_list_scripts(projectId)` → if a script named like "Google" exists, reuse
   its `id`; else `demodu_create_script(projectId, name, scriptJson)` with the
   bundled `google-test-script.json` and keep the new `id`.
3. `demodu_start_recording(scriptId)` → keep `recordingId`. Warn the user the
   google script pauses twice for manual take-control (captcha / pressing Enter)
   in the studio live view.
4. Poll `demodu_recording_status(recordingId)` ~every 10s until `done` or `failed`.
   - `awaiting_human`: tell the user to take control in the studio, finish, Resume.
   - `failed`: report the error and stop.
5. `demodu_recording_playback(recordingId)` → the playback URL.
6. **Download it via the terminal** (this is what the Claude Code hook does
   automatically; in Cursor you run it yourself):
   ```bash
   mkdir -p ./demodu-recordings
   curl -fL --retry 1 -o "./demodu-recordings/<recordingId>.mp4" "<playback-url>"
   # macOS notify (optional):
   osascript -e 'display notification "Saved <recordingId>.mp4" with title "demodu — video ready" sound name "Glass"'
   ```
7. Report the saved path: `./demodu-recordings/<recordingId>.mp4`.
