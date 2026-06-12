# demodu-recorder

A Claude Code plugin (Cursor-compatible) that records the demodu **google test
script** via the demodu MCP server and **auto-downloads the video when it's
ready**.

It bundles:
- the **demodu MCP server** (`https://mcp.demodu.com/mcp`) — OAuth sign-in on first use,
- a `/record-google-demo` **slash command** that orchestrates the recording,
- a **PostToolUse hook** on `demodu_recording_playback` that downloads the MP4 +
  pops a desktop notification the moment the render is ready,
- the **google test scene-DSL** it records (`scripts/google-test-script.json`).

## Install (Claude Code)

```bash
# from the repo root (the dir that contains plugins/)
claude plugin marketplace add ./plugins
claude plugin install demodu-recorder@demodu
```

Then, in a Claude Code session:

```
/record-google-demo
```

On first tool use Claude Code runs the demodu **OAuth browser sign-in**. After
that the command:
1. creates the google script in your account if it isn't there yet,
2. starts the recording,
3. polls until it's done (the script pauses twice for manual **take-control** in
   the studio — captcha + pressing Enter),
4. fetches the playback URL — at which point the **hook fires** and saves the
   video to `./demodu-recordings/<recordingId>.mp4` with a desktop notification.

## Install (Cursor)

Cursor has no hook system, so the download is done inline by the agent.

1. Copy `cursor/mcp.json` → your project's `.cursor/mcp.json` (or merge the
   `demodu` entry into an existing one). Enable it in Cursor → Settings → MCP and
   complete the OAuth sign-in.
2. Copy `cursor/commands/record-google-demo.md` → `.cursor/commands/`.
3. Run the command; the agent records and then `curl`s the MP4 down itself.

## How the "video ready" hook works

`hooks/hooks.json` registers a `PostToolUse` matcher on
`mcp__demodu__demodu_recording_playback`. That tool only returns a URL once the
render is finished, so its success **is** the "video ready" event.
`hooks/on-video-ready.sh` reads the hook payload on stdin, pulls the recording id
and the playback URL out of it, downloads the MP4 next to your project, and
notifies you. It always exits 0 — a download hiccup never breaks the agent.

Output: `./demodu-recordings/<recordingId>.mp4`.

## Notes

- **No admin via MCP** — the demodu MCP exposes only customer tools; this plugin
  can record, manage scripts, and read usage, never touch admin.
- The google script targets `https://www.google.com` and deliberately pauses for
  take-control so you can clear a captcha — that's the point of the demo.
