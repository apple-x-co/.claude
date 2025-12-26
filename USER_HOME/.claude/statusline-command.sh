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

# Output the status line
printf "📁 %s | 🌿 %s | 🤖 %s | 📏 %s" "${cwd##*/}" "$git_branch" "$model" "$context_info"
