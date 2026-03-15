# Tool Preferences

- Prefer built-in tools (Grep, Glob, Read) over shell equivalents.
- rtk is active on bash commands via a PreToolUse hook. Shell output is automatically
  compressed. No action needed.
- For dbt metadata questions, prefer `jq` over loading all of `target/manifest.json`
  into context. Query only the fields you need.
- For long or context-heavy sessions, use `/context` to inspect context overhead and
  disable unused MCP servers before broad multi-file work.
- When searching for code structure patterns (function signatures, class definitions,
  decorators), `sg` (ast-grep) provides structural matching if installed. Check availability
  with `which sg` before use. Fall back to grep if unavailable.
