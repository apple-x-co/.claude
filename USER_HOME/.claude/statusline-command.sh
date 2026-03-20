#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# Get git branch if in a git repository (skip optional locks)
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$git_branch" ]; then
        git_branch="$git_branch"
    fi
fi

# Calculate context window percentage
usage=$(echo "$input" | jq '.context_window.current_usage')
context_info="(unused context)"
if [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    pct=$((current * 100 / size))
    context_info="${pct}% context"
fi

# Calculate rate limit info (5-hour window)
rate_info=""
rate_used=$(echo "$input" | jq '.rate_limits.five_hour.used_percentage // empty')
rate_resets_at=$(echo "$input" | jq '.rate_limits.five_hour.resets_at // empty')
if [ -n "$rate_used" ] && [ -n "$rate_resets_at" ]; then
    now=$(date +%s)
    remaining_sec=$((rate_resets_at - now))
    if [ "$remaining_sec" -le 0 ]; then
        reset_str="まもなくリセット"
    else
        remaining_min=$((remaining_sec / 60))
        hours=$((remaining_min / 60))
        mins=$((remaining_min % 60))
        if [ "$hours" -gt 0 ]; then
            reset_str="${hours}h${mins}m"
        else
            reset_str="${mins}m"
        fi
    fi
    rate_info=" | ⚡ ${rate_used}% (↺${reset_str})"
fi

# Output the status line
printf "📁 %s | 🌿 %s | 🤖 %s | 📏 %s%s" "${cwd##*/}" "$git_branch" "$model" "$context_info" "$rate_info"
