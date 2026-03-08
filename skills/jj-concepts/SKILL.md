---
name: jj-concepts
description: Background knowledge about jujutsu (jj) version control for Claude
---

# Jujutsu (jj) Version Control Concepts

This project uses **jujutsu (jj)** instead of git. jj is a Git-compatible VCS with a different mental model. Always use `jj` commands, never `git`.

## Core Differences from Git

### No staging area
The working copy IS the current commit (`@`). Every file change is automatically part of `@`. There is no `git add` equivalent — just edit files and commit.

### Bookmarks, not branches
jj uses **bookmarks** (similar to git branches but more explicit). They don't move automatically — you advance them with `jj bookmark advance` (`jj ba`).

### Conflicts are data
Conflicts are stored in commits, not blocking states. You can commit conflicted files and resolve later. `jj status` shows conflicts.

### Immutable history
All commits are immutable. "Amending" creates a new commit that replaces the old one. The old commit is still in the repo (garbage collected later).

## Revset Syntax

| Symbol | Meaning |
|--------|---------|
| `@` | Current working copy commit |
| `@-` | Parent of working copy |
| `@--` | Grandparent of working copy |
| `trunk()` | Main branch tip (usually tracks remote main/master) |
| `mine()` | Commits authored by you |
| `bookmarks()` | All bookmarked commits |
| `heads(mine())` | Latest commits by you |

## Common Operations

```bash
jj status              # Show working copy changes (like git status)
jj diff                # Show changes in working copy
jj log                 # Show commit log (default: your recent commits)
jj new                 # Create new empty change on top of @
jj commit -m "msg"     # Finalize @ with message, create new empty @
jj commit -m "msg" f1 f2  # Commit only specific files
jj describe -m "msg"   # Set/change description of @ without finalizing
jj squash              # Squash @ into parent (@-)
jj edit <rev>          # Make an older commit the working copy
jj bookmark set <name> # Set bookmark at current commit
jj bookmark advance    # Advance bookmarks forward (jj ba)
jj git push            # Push to git remote
jj git fetch           # Fetch from git remote
```

## Workspace Model

jj workspaces are like git worktrees but better:
- Each workspace has its own `@` (working copy)
- All workspaces share the same commit graph
- No merging needed between workspaces — commits are immediately visible
- Create: `jj workspace add <name> --revision @`
- Remove: `jj workspace forget <name>`

## Reference

See `references/git-to-jj.md` for a comprehensive git-to-jj command mapping.
