#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cw_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
worktree=$(echo "$input" | jq -r '.worktree.name // empty')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
current_dir=$(echo "$input" | jq -r '.worktree.original_cwd // empty')
rl_5h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | awk '{printf "%.0f", $1}')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
tokens=$(echo "$input" | jq -r '
  (.context_window.current_usage // {}) as $u
  | (($u.input_tokens // 0)
     + ($u.cache_creation_input_tokens // 0)
     + ($u.cache_read_input_tokens // 0)) as $t
  | if $t > 0 then $t else empty end
')

# Format a token count into a human-readable string (e.g. 12345 -> "12.3k").
fmt_tokens() {
  awk -v t="$1" 'BEGIN {
    if (t >= 1000000) printf "%.1fM", t/1000000
    else if (t >= 1000) printf "%.1fk", t/1000
    else printf "%d", t
  }'
}

if [ -n "$used" ]; then
  used_pct=$(printf "%.0f" "$used")
else
  used_pct=0
fi

# Fall back to deriving tokens from used_percentage * context_window_size
# when current_usage is null (e.g. before the first API call).
if [ -z "$tokens" ] && [ -n "$used" ] && [ -n "$cw_size" ]; then
  tokens=$(awk -v p="$used" -v s="$cw_size" 'BEGIN { printf "%d", (p/100)*s }')
fi

if [ -n "$cw_size" ]; then
  size_str=$(fmt_tokens "$cw_size")
  tokens_str=$(fmt_tokens "${tokens:-0}")
  usage_detail="${tokens_str}/${size_str}"
elif [ -n "$tokens" ]; then
  usage_detail="$(fmt_tokens "$tokens")"
else
  usage_detail=""
fi

if [ -n "$worktree" ]; then
  worktree_str="${worktree}"
else
  worktree_str="no worktree"
fi

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

git_str=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')

  git_str="$branch"
  [ "$staged" -gt 0 ] && git_str="${git_str} $(printf "${GREEN}+${staged}${RESET}")"
  [ "$modified" -gt 0 ] && git_str="${git_str} $(printf "${YELLOW}~${modified}${RESET}")"
else
  git_str="no branch"
fi


if [ -n "$total_cost" ]; then
  cost_display=$(awk "BEGIN { printf \"%.2f\", $total_cost }")
  block_str="\$${cost_display}"
else
  block_str="\$0.00"
fi

make_bar() {
  pct="$1"
  width=10
  filled=$(( pct * width / 100 ))
  empty=$(( width - filled ))
  bar=""
  i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$(( i + 1 )); done
  while [ $i -lt $width ];  do bar="${bar}░"; i=$(( i + 1 )); done
  printf "%s" "$bar"
}

format_rl() {
  pct="$1"
  reset_ts="$2"
  label="$3"
  [ -z "$pct" ] && return
  if [ "$pct" -ge 90 ]; then color="$RED"
  elif [ "$pct" -ge 70 ]; then color="$YELLOW"
  else color="$GREEN"
  fi
  reset_time=$(date -r "$reset_ts" "+%-I:%M%p" 2>/dev/null || date -d "@$reset_ts" "+%-I:%M%p" 2>/dev/null)
  bar=$(make_bar "$pct")
  printf "${color}${label} ${bar} ${pct}%% resets ${reset_time}${RESET}"
}

rate_limit_str=""
rate_limit_str="${rate_limit_str}$(format_rl "$rl_5h_pct" "$rl_5h_reset" "5h")"
# rate_limit_str="${rate_limit_str}$(format_rl "$rl_7d_pct" "$rl_7d_reset" "7d")"

repo_root=$(cd "$current_dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || echo "$current_dir")
dir_display=$(basename "$repo_root")

# Color-coded context window bar: green <70%, yellow 70-89%, red >=90%.
if [ "$used_pct" -ge 90 ]; then ctx_color="$RED"
elif [ "$used_pct" -ge 70 ]; then ctx_color="$YELLOW"
else ctx_color="$GREEN"
fi
ctx_bar=$(make_bar "$used_pct")
if [ -n "$usage_detail" ]; then
  ctx_str=$(printf "${ctx_color}${ctx_bar} ${used_pct}%% (${usage_detail})${RESET}")
else
  ctx_str=$(printf "${ctx_color}${ctx_bar} ${used_pct}%%${RESET}")
fi

if [ -n "$effort" ]; then
  printf "🤖 %s | 💪 %s | 🧠 %s | 💰 %s | ⏱️ %s\n📁 %s | 🌳 %s | 🌿 %s" "$model" "$effort" "$ctx_str" "$block_str" "$rate_limit_str" "$dir_display" "$worktree_str" "$git_str"
else
  printf "🤖 %s | 🧠 %s | 💰 %s | ⏱️ %s\n📁 %s | 🌳 %s | 🌿 %s" "$model" "$ctx_str" "$block_str" "$rate_limit_str" "$dir_display" "$worktree_str" "$git_str"
fi