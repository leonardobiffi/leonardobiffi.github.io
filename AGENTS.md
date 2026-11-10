# AGENTS.md - Leonardo Biffi Blog (Jekyll + Chirpy)

## Quick Commands

```bash
# Install deps
task install           # or: bundle install

# Run dev server (live reload)
task dev               # or: bundle exec jekyll serve

# Build for production
task build             # or: JEKYLL_ENV=production bundle exec jekyll build

# Test built site (internal links only)
bash tools/test.sh

# Create new post (manual - see front matter template below)
touch "_posts/$(date +%Y-%m-%d)-slug.md"
```

## Post Front Matter Template

Copy from `_posts/2026-09-22-kse-kubernetes-secret-encoding.md`:

```yaml
---
title: "Post Title"
description: "One-sentence summary for SEO/social"
date: 2026-09-22 10:00:00 +0000
lang: en
permalink: /en/posts/slug-here/
categories: [DevOps, Kubernetes, CLI]   # max 2-3, match _config.yml categories
tags: [Kubernetes, Secrets, CLI, Golang]  # lowercase, specific
icons: [kubernetes, golang, cli]         # matches assets/img/icons/*.svg
---
```

**Rules:**
- `permalink`: must follow `/en/posts/<slug>/` pattern (see `_config.yml:194`)
- `categories`: used for site navigation, keep consistent
- `tags`: free-form but reuse existing when possible
- `icons`: filenames in `assets/img/icons/` without extension

## Project Structure

```
_posts/           # blog posts (this is where you write)
_config.yml       # site config - DO NOT modify permalink pattern
assets/img/icons/ # SVG icons for post front matter
tools/test.sh     # CI-equivalent test (htmlproofer)
tools/run.sh      # alternative dev runner
.github/workflows/pages-deploy.yml  # CI: build + test + deploy
```

## CI Pipeline (GitHub Actions)

Runs on push to `main`/`master`:
1. `bundle exec jekyll build` (production)
2. `htmlproofer` on `_site/` (internal links only)
3. Deploy to GitHub Pages

**Local equivalent:** `task build && bash tools/test.sh`

## Writing Conventions

- **Code blocks**: Use `bash` for commands, `yaml` for config
- **Links**: Reference-style at bottom of post (see KSE post lines 36-40)
- **Images**: Place in `assets/images/`, reference as `/assets/images/file.png`
- **Categories**: DevOps, Kubernetes, CLI, Golang, Cloud-Native (existing set)

## Gotchas

- `baseurl: ""` in `_config.yml` - site runs at root
- Permalink pattern is hardcoded in `_config.yml:194` - don't change
- `htmlproofer` ignores localhost/127.0.0.1 URLs (see `tools/test.sh:66`)
- Ruby 3.4 required (per CI workflow)
- Theme version pinned in Gemfile (`~> 7.6`)
