---
title: "Syncing Public Container Images to a Private Registry with regsync"
description: "Learn how to use regsync to automatically mirror public container images to your private registry for air-gapped environments and supply chain security."
date: 2026-10-02 14:05:13 -0400
lang: en
permalink: /en/posts/syncing-container-images-regsync/
categories: [DevOps, Kubernetes, CLI]
tags: [container, registry, regsync, kubernetes, docker, supply-chain]
icons: [kubernetes, docker, cli]
---

## Introduction

If you're running a private container registry, you've likely faced the need to mirror public images for security, compliance, or availability reasons. `regsync` from the [regclient](https://regclient.org/) project makes this straightforward.

## Why regsync?

- **Declarative configuration** - Define what to sync in YAML
- **Multiple operating modes** - Run once, on a schedule, or as a persistent server
- **Smart filtering** - Sync only specific tags using regex or semantic versioning
- **Handles authentication** - Integrates with Docker credential helpers

## Quick Example: Mirroring `securego/gosec`

Let's sync the `securego/gosec` security scanner image from Docker Hub to a private registry.

### Prerequisites

- A private registry (e.g., Harbor, Nexus, or a plain `registry:2` container)
- `regsync` installed (`go install github.com/regclient/regclient/cmd/regsync@latest` or download from [GitHub releases](https://github.com/regclient/regclient/releases))

### Configuration

Create `regsync.yaml`:

```yaml
version: 1
creds:
  # Only needed if your private registry requires auth not in ~/.docker/config.json
  - registry: my-registry.example.com
    user: syncuser
    pass: "{{file \"/var/run/secrets/registry_token\"}}"
defaults:
  interval: 6h
sync:
  - source: docker.io/securego/gosec
    target: my-registry.example.com/security/gosec
    type: repository
    tags:
      allow:
        - "latest"
        - "v[0-9]+\\.[0-9]+\\.[0-9]+"
    referrers: true
    digestTags: true
```

### Key Settings Explained

| Setting | Purpose |
|---------|---------|
| `type: repository` | Sync all tags from the source repo |
| `tags.allow` | Only sync `latest` and semantic version tags (e.g., `v2.18.0`) |
| `referrers: true` | Also copy SBOMs, signatures, and other referrers |
| `digestTags: true` | Create immutable digest tags (e.g., `sha256-abc123...`) |
| `interval: 6h` | Check for updates every 6 hours in server mode |

### Run It

**One-time sync:**
```bash
regsync once -c regsync.yaml
```

**Persistent server (recommended for production):**
```bash
regsync server -c regsync.yaml
```

**Check what would be synced without copying:**
```bash
regsync check -c regsync.yaml
```

### Verifying the Sync

```bash
# List tags in your private registry
regctl tag ls my-registry.example.com/security/gosec

# Inspect a specific image
regctl image inspect my-registry.example.com/security/gosec:latest
```

## Pro Tips

**Use credential helpers** instead of storing passwords in config:
```yaml
creds:
  - registry: my-registry.example.com
    credHelper: ecr-login  # For AWS ECR
```

**Filter by semantic version range** to only get stable releases:
```yaml
tags:
  semverRange:
    - ">=2.18.0 <3.0.0"
```

**Backup before overwriting** (useful for mutable tags like `latest`):
```yaml
sync:
  - source: docker.io/securego/gosec
    target: my-registry.example.com/security/gosec
    type: repository
    backup: "backup-{{.Ref.Tag}}-{{now.Format \"20060102\"}}"
```

## Going Further

- Run `regsync` as a **Kubernetes CronJob** or **systemd service**
- Monitor with the built-in **Prometheus metrics** (`--metrics-port`)
- Use **templates** for dynamic target paths across multiple repos
- Combine with `regctl` for registry management in the same toolkit

---

*regsync is part of the [regclient](https://github.com/regclient/regclient) suite - a Swiss Army knife for container registries that also includes `regctl` (CLI) and `regbot` (automation server).*
