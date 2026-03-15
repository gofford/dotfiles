#!/usr/bin/env bash
# Status line for Claude Code
# Output: model | context bar | git branch [dirty]
# Requires: jq, git

data=$(cat)

# ── Model ────────────────────────────────────────────────────────────────────
model=$(echo "$data" | jq -r '.model.display_name // .model.id // "claude"')

# ── Context window ───────────────────────────────────────────────────────────
max_ctx=$(echo "$data" | jq -r '.context_window.context_window_size // 200000')
used_pct=$(echo "$data" | jq -r '.context_window.used_percentage // empty')

BLUE='\033[34m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

if [ -z "$used_pct" ] || [ "$used_pct" = "null" ]; then
  ctx_str="○○○○○○○○○○ …"
else
  pct=$(printf "%.0f" "$used_pct" 2>/dev/null || echo "0")
  [ "$pct" -gt 100 ] 2>/dev/null && pct=100

  used_k=$(( max_ctx * pct / 100 / 1000 ))
  max_k=$(( max_ctx / 1000 ))

  if   [ "$pct" -gt 80 ]; then COLOR="$RED"
  elif [ "$pct" -gt 50 ]; then COLOR="$YELLOW"
  else                         COLOR="$BLUE"
  fi

  bar=""
  filled=$(( pct / 10 ))
  for i in 0 1 2 3 4 5 6 7 8 9; do
    if [ "$i" -lt "$filled" ]; then
      bar="${bar}${COLOR}●${RESET}"
    else
      bar="${bar}○"
    fi
  done

  ctx_str="${bar} ${used_k}k/${max_k}k (${pct}%)"
fi

# ── Git ───────────────────────────────────────────────────────────────────────
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  dirty=""
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    dirty=" *"
  fi
  git_str="${branch}${dirty}"
else
  git_str=""
fi

# ── Assemble ──────────────────────────────────────────────────────────────────
if [ -n "$git_str" ]; then
  printf '%b\n' "${model}  ${ctx_str}  ${git_str}"
else
  printf '%b\n' "${model}  ${ctx_str}"
fi
