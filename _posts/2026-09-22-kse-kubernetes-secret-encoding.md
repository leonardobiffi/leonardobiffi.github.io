---
title: "KSE: Encode and Decode Kubernetes Secrets from the CLI"
description: "A Golang CLI tool to encode and decode Kubernetes Secrets while preserving YAML file order and supporting multiple secrets in a single file."
date: 2026-09-22 10:00:00 +0000
lang: en
permalink: /en/posts/kse-kubernetes-secret-encoding-cli-tool/
categories: [DevOps, Kubernetes, CLI]
tags: [Kubernetes, Secrets, CLI, Golang, DevOps]
icons: [kubernetes, golang, cli]
---

## Introduction

Managing Kubernetes Secrets is a daily task for anyone working with container orchestration. The built-in `kubectl` approach of base64-encoding values works, but it becomes tedious when you're dealing with multiple secrets across different files, or when you need to quickly inspect a secret's actual values without manually decoding each field.

[KSE (Kubernetes Secret Encoding)](https://github.com/leonardobiffi/kse) is a CLI tool built in Go that simplifies this workflow. It handles both encoding and decoding, preserves YAML file order, supports multiple secrets in a single file, and works with stdin, files, or entire directories.

## Why Another Secret Tool?

The usual workflow looks like this:

```bash
# To decode a single secret
kubectl get secret my-secret -o yaml | grep "password:"

# Copy the encoded value to use, e.g., decode it with base64 -d
echo "c3VwZXJzZWNyZXQ=" | base64 -d

# To encode a new secret
echo -n "supersecret" | base64
```

This works for one-off tasks, but breaks down when:
- You have a directory of secret manifests and need to decode all of them
- You want to preserve the original YAML structure and ordering
- You're piping secrets between tools in a CI/CD pipeline
- You're working with multiple secrets in a single YAML file

KSE addresses these scenarios with a simpler interface.

## Installation

```bash
# Via install script (requires jq and curl)
curl -fsSL https://raw.githubusercontent.com/leonardobiffi/kse/master/scripts/install.sh | sh

# Or with Go
go install github.com/leonardobiffi/kse@latest
```

## Decoding Secrets

### From a file or directory

```bash
# Decode all secrets in a directory
kse decode -o -f ./k8s/secrets/

# Decode a single file
kse decode -o -f ./k8s/secrets/production.yaml
```

The `-o` flag outputs the decoded result to stdout. The tool recursively finds all Secret resources in the target path.

### From stdin

```bash
# From kubectl directly
kubectl get secret my-secret -o yaml | kse decode

# From a file via cat
cat secret.yaml | kse decode
```

This makes it easy to integrate into pipelines:

```bash
kubectl get secrets -n production -o yaml | kse decode | grep -i password
```

## Encoding Secrets

Encoding works the same way, just in reverse:

```bash
# Encode all secrets in a directory
kse encode -o -f ./k8s/secrets/

# Encode from stdin
cat plain-secret.yaml | kse encode
```

The tool expects the input to have plaintext `stringData` fields and converts them to base64-encoded `data` fields, which is what Kubernetes expects.

## How It Works

KSE looks for Kubernetes Secret resources (kind: Secret) in your YAML files and:

1. **Decode**: Reads the `data` field (base64), decodes each value, and outputs the secret with `stringData` populated
2. **Encode**: Reads the `stringData` field, base64-encodes each value, and outputs the secret with `data` populated

It preserves:
- YAML key ordering (using `gopkg.in/yaml.v3`)
- Comments in the original file
- Multiple Secret resources in a single file
- All other Secret metadata (labels, annotations, type)

## Example

Input (encoded secret):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: production
type: Opaque
data:
  username: YWRtaW4=
  password: c3VwZXJzZWNyZXQ=
```

After `kse decode`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: production
type: Opaque
stringData:
  username: admin
  password: supersecret
```

## Conclusion

KSE fills a specific gap: making Kubernetes Secret encoding/decoding a one-command operation that works with the file-based workflows many teams already use. If you're managing secrets as YAML manifests in Git (GitOps), it removes the friction of constantly switching between base64 and plaintext.

Try it out: `go install github.com/leonardobiffi/kse@latest`
