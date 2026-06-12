# demodu plugins

A Claude Code plugin marketplace for [demodu](https://demodu.com) — drive your
demodu account (record demos, manage scripts, download videos) from Claude Code
or Cursor via the demodu MCP server.

## Install (Claude Code)

```bash
claude plugin marketplace add tech-sumit/demodu-plugins
claude plugin install demodu-recorder@demodu
```

Then restart Claude Code and run `/record-google-demo`.

## Plugins

### `demodu-recorder`
Records the demodu google test script through the demodu MCP server
(`https://mcp.demodu.com/mcp`, OAuth sign-in on first use) and **auto-downloads
the video when the render is ready** via a PostToolUse hook on
`demodu_recording_playback`. Cursor-compatible (the download is done inline by
the agent, since Cursor has no hooks).

See [`demodu-recorder/README.md`](./demodu-recorder/README.md).

## License

MIT
