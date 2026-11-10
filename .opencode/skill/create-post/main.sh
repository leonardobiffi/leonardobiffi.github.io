#!/usr/bin/env bash
# create-post - Creates a new blog post with proper front matter

set -euo pipefail

# Get slug from user
read -p "Post slug (e.g., my-new-post): " SLUG

if [[ -z "$SLUG" ]]; then
    echo "Error: Slug is required"
    exit 1
fi

# Sanitize slug
SLUG=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

# Get title from user
read -p "Post title: " TITLE

if [[ -z "$TITLE" ]]; then
    echo "Error: Title is required"
    exit 1
fi

# Get description
read -p "One-sentence description (SEO/social): " DESCRIPTION

# Get categories
echo "Available categories: DevOps, Kubernetes, CLI, Golang, Cloud-Native"
read -p "Categories (comma-separated, max 2-3): " CATEGORIES_INPUT

# Get tags
read -p "Tags (comma-separated, lowercase): " TAGS_INPUT

# Get icons
echo "Available icons in assets/img/icons/:"
ls assets/img/icons/*.svg 2>/dev/null | sed 's|assets/img/icons/||; s|\.svg||' | tr '\n' ' '
echo
read -p "Icons (comma-separated, no extension): " ICONS_INPUT

# Build front matter
DATE=$(date '+%Y-%m-%d %H:%M:%S %z')
FILENAME="_posts/${DATE:0:10}-${SLUG}.md"

# Convert comma-separated to YAML arrays
format_array() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo "[]"
        return
    fi
    echo "$input" | sed 's/, */\", \"/g' | sed 's/^/[ "/; s/$/ "]/'
}

CATEGORIES=$(format_array "$CATEGORIES_INPUT")
TAGS=$(format_array "$TAGS_INPUT")
ICONS=$(format_array "$ICONS_INPUT")

# Create the post
cat > "$FILENAME" <<EOF
---
title: "$TITLE"
description: "$DESCRIPTION"
date: $DATE
lang: en
permalink: /en/posts/$SLUG/
categories: $CATEGORIES
tags: $TAGS
icons: $ICONS
---

Content here...
EOF

echo "Created: $FILENAME"
echo "Edit the file to add your content."