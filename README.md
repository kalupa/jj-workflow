# jj-workflow

A Claude Code plugin that teaches Claude to use [jujutsu (jj)](https://martinvonz.github.io/jj/) instead of git.

## What it does

- **Intercepts git commands** in jj repos and suggests the jj equivalent
- **`/jj-commit`** — selective file grouping and commit workflow
- **`/develop`** — enter isolated jj workspaces for development
- **Background knowledge** — jj concepts, revset syntax, and a git-to-jj command mapping

## Installation

Add to your `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "/path/to/jj-workflow": true
  }
}
```

Replace `/path/to/jj-workflow` with the actual path to this directory.

## Structure

```
.claude-plugin/plugin.json    Plugin manifest
hooks/hooks.json              Hook definitions (git blocking, worktree lifecycle)
hooks/scripts/block-git.sh    Git command interceptor
commands/jj-commit.md         /jj-commit slash command
commands/develop.md           /develop slash command
skills/jj-concepts/           Background jj knowledge for Claude
scripts/cleanup-workspace.sh  Workspace cleanup helper
```

## Pre-commit validation

The `/jj-commit` command checks for `.claude/jj-pre-commit.sh` in your project root. If it exists and is executable, it runs before committing. Use this for project-specific validation:

```bash
# Example: .claude/jj-pre-commit.sh for an hledger project
#!/usr/bin/env bash
hledger check -s -f main.journal

# Example: for a Rust project
#!/usr/bin/env bash
cargo check
```

## How git blocking works

The PreToolUse hook intercepts any `git` command when a `.jj/` directory is found in the directory tree. It maps the git subcommand to its jj equivalent and blocks with a helpful message:

```
BLOCK: This is a jj repository. Use jj instead of git.
  git status → jj status
```

In non-jj repos, git commands pass through normally.

## Workspace model

`/develop` creates jj workspaces via Claude Code's `EnterWorktree` mechanism. Unlike git worktrees, jj workspaces share the same commit graph — no merging needed. Clean up with `scripts/cleanup-workspace.sh <name>`.
