# claude-statusline

A compact, two-line [Claude Code status line](https://code.claude.com/docs/en/statusline) that shows model, reasoning effort, context window usage (with token count), session cost, 5-hour rate limit, and git/worktree state.

![Status line](docs/images/statusline.png)

With the 5-hour rate-limit bar enabled:

![Status line with rate limits](docs/images/statusline_with_rate-limits.png)

## What it shows

Line 1 — `🤖 model | 💪 effort | 🧠 context | 💰 cost | ⏱️ rate limit`
- **Context bar:** color-coded (green <70%, yellow 70–89%, red ≥90%) with `used/max` token counts (e.g. `42% (84.0k/200.0k)`).
- **Cost:** session `cost.total_cost_usd`.
- **Rate limit:** 5-hour usage bar with reset time. The 7-day bar is in the script, commented out.

Line 2 — `📁 repo | 🌳 worktree | 🌿 branch`
- **Git:** branch plus `+staged` / `~modified` counts when non-zero.

## Requirements

- [Claude Code](https://code.claude.com/docs/en/overview)
- `jq`, `awk`, `git`, `date` (standard on macOS/Linux)

## Setup

1. Clone or copy `statusline-command.sh` somewhere stable:

   ```sh
   git clone https://github.com/<your-user>/claude-statusline.git ~/.claude/claude-statusline
   chmod +x ~/.claude/claude-statusline/statusline-command.sh
   ```

2. Point Claude Code at it in `~/.claude/settings.json`:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/claude-statusline/statusline-command.sh",
       "padding": 2
     }
   }
   ```

3. Start a new Claude Code session — the status line appears at the bottom of the interface.

## Test locally

```sh
echo '{
  "model": { "display_name": "Claude Opus 4.7" },
  "context_window": {
    "used_percentage": 42,
    "context_window_size": 200000,
    "current_usage": {
      "input_tokens": 50000,
      "cache_creation_input_tokens": 10000,
      "cache_read_input_tokens": 25000,
      "output_tokens": 1500
    }
  },
  "cost": { "total_cost_usd": 1.23 }
}' | sh ./statusline-command.sh
```

## Customize

- **Enable the 7-day rate-limit bar:** uncomment the second `format_rl` line near the bottom of `statusline-command.sh`.
- **Hardcode context window size:** replace the `cw_size=...jq...` line with `cw_size=200000` (useful on Pro, where Claude Code may report 1M but the effective window is 200k).
- **Bar width / thresholds:** edit `make_bar` (width) and the color thresholds in `format_rl` and the context block.

## Reference

- Source script: [`statusline-command.sh`](statusline-command.sh)
- Claude Code status line docs: <https://code.claude.com/docs/en/statusline>
- Available JSON fields: <https://code.claude.com/docs/en/statusline#available-data>

## License

[Apache 2.0](LICENSE)
