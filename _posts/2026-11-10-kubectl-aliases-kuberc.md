---
title: "Native kubectl Aliases with kuberc"
description: "Kubernetes 1.33 introduced kuberc, a native YAML file for kubectl aliases and defaults. Here is how to set it up, test it, and stop stuffing aliases into your shell profile."
date: 2026-11-10 07:20:00 -0400
lang: en
permalink: /en/posts/kubectl-aliases-kuberc/
categories: [DevOps, Kubernetes, CLI]
tags: [Kubernetes, kubectl, aliases, CLI, kuberc]
icons: [kubernetes, cli]
---

## Introduction

For years, kubectl aliases lived in `.bashrc` or `.zshrc`:

```bash
alias k=kubectl
alias kgp="kubectl get pods"
alias kaf="kubectl apply -f"
```

This works, but it has two problems. Shell aliases are tied to one shell, so a new machine or a switch from zsh to fish means starting over. And they cannot change kubectl's default flags in a structured way.

Starting with Kubernetes v1.33, kubectl can read aliases from a dedicated YAML file called `kuberc` (kubectl user preferences). The feature is beta since v1.34 and enabled by default there. It gives you a single, version-controllable place for aliases and default options.

This post walks through the setup on macOS and Linux. The general flow follows the [DevOpsCube kuberc guide](https://devopscube.com/kubectl-aliases/), updated to match the current upstream schema.

## Check your kubectl version

You need kubectl 1.33 or newer:

```bash
kubectl version --client
```

If you are on an older version, upgrade first. The official instructions live in the [kubectl install docs](https://kubernetes.io/docs/tasks/tools/).

## Where the file lives

The default path is:

- Linux and macOS: `~/.kube/kuberc`
- Windows: `%USERPROFILE%\.kube\kuberc`

You can point kubectl at a different file with the `--kuberc` flag or the `KUBERC` environment variable:

```bash
kubectl --kuberc ./project-kuberc get pods
```

Unlike `kubeconfig`, a `kuberc` file contains no cluster addresses or credentials. That makes it safe to commit to a dotfiles repo and share with your team.

## Enable it on 1.33

If you are on v1.33 exactly, the feature still needs an opt-in environment variable:

```bash
export KUBECTL_KUBERC=true
```

Add it to your shell profile if you want it to persist. On v1.34 and later you can skip this step, because kuberc is beta and on by default.

## Create the config

Create `~/.kube/kuberc` with the current API version:

```yaml
apiVersion: kubectl.config.k8s.io/v1beta1
kind: Preference

aliases:
  - name: kgp
    command: get
    appendArgs:
      - pods

  - name: klogs
    command: logs
    options:
      - name: follow
        default: "true"
      - name: tail
        default: "50"

  - name: kgy
    command: get
    options:
      - name: output
        default: yaml

defaults:
  - command: apply
    options:
      - name: server-side
        default: "true"

  - command: delete
    options:
      - name: interactive
        default: "true"

  - command: exec
    options:
      - name: stdin
        default: "true"
      - name: tty
        default: "true"
```

A few things worth understanding about the schema:

| Field | Purpose |
|-------|---------|
| `name` | The alias you type. It cannot collide with a built-in kubectl command |
| `command` | The real command to run, including subcommands like `create namespace` |
| `options` | Default flag values. Anything you pass on the command line wins |
| `prependArgs` | Arguments inserted right after the command |
| `appendArgs` | Arguments appended at the end of the command |

The `defaults` section applies to commands you did not alias. In the example above, `kubectl apply` gets server-side apply by default, `kubectl delete` asks for confirmation, and `kubectl exec` becomes interactive without typing `-it`.

If you are coming from an older guide, note that the v1beta1 schema uses `defaults` and `options`. The older `overrides` and `flags` keys belong to the alpha format and are not what you want on a current kubectl.

## Try it out

No restart needed. kubectl reads the file on each invocation:

```bash
# Alias with appended args
kubectl kgp

# Defaults from options, with follow and tail
kubectl klogs my-pod

# YAML by default, overridable per call
kubectl kgy deploy my-app
kubectl kgy deploy my-app -o json

# Interactive delete thanks to defaults
kubectl delete namespace dev-project-01
```

If a command does not behave as expected, drop `--v=8` in front of it to see how kubectl resolved the alias and its arguments.

## My daily aliases

After a few years of tuning `.zshrc`, I have aliases for everything: kubectl, Terraform, AWS, git, and a pile of one-off helpers. When I moved to kuberc, I split them by one rule: if it maps to a single kubectl command, it goes in the YAML file; if it needs a pipe, a loop, or another tool, it stays in the shell.

### kubectl aliases in kuberc

These are the ones I use every day:

```yaml
apiVersion: kubectl.config.k8s.io/v1beta1
kind: Preference

aliases:
  - name: kgp
    command: get
    appendArgs:
      - pods

  - name: kgr
    command: get
    appendArgs:
      - pods
    options:
      - name: field-selector
        default: status.phase==Running

  - name: ksys
    command: get
    options:
      - name: namespace
        default: kube-system

  - name: klogs
    command: logs
    options:
      - name: follow
        default: "true"
      - name: tail
        default: "50"
```

That gives me `kubectl kgp`, `kubectl kgr` for running pods, `kubectl ksys pods` for the system namespace, and `kubectl klogs my-pod` with follow and a 50-line tail already set.

### What stays in `.zshrc`

The rest is shell territory. A short list of functions that earn their keep:

```bash
# Every pod that is not Running or Completed
kpoderror() {
  kubectl get pods --all-namespaces | awk '!/Running|Completed/' | column -t -s '  '
}

# Pods scheduled on a specific node
kpodnode() {
  kubectl get pods --all-namespaces --field-selector spec.nodeName=$1
}

# Delete pods whose name matches a pattern
kdelpod() {
  kubectl get pods --no-headers=true | awk '/'${1}'/{print $1}' | xargs kubectl delete pod
}
```

Autocompletion works with kuberc aliases too, so pressing Tab after `kubectl kg` will suggest the alias.

## Turn it off

For troubleshooting, disable kuberc temporarily:

```bash
export KUBERC=off
```

On 1.33 you can also flip the feature gate:

```bash
export KUBECTL_KUBERC=false
```

That is enough to tell whether a strange kubectl behavior comes from your preferences file or from the cluster.

## Conclusion

`kuberc` moves kubectl aliases out of shell startup files and into a declarative YAML file that kubectl itself understands. You get one config for every shell, defaults that apply across commands, and a file you can version, review, and share. If you are on 1.33 or newer, it is worth migrating your most-used aliases today.
