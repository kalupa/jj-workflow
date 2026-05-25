---
name: jj-sync
description: Fetch from the remote and rebase in-progress work onto the updated trunk
disable-model-invocation: true
---

# Jujutsu Sync Workflow

Catch up with the remote and replay your in-progress changes onto the latest trunk. This is jj's equivalent of `git pull --rebase`, but fetch and rebase are separate, explicit steps.

## Arguments
- `$ARGUMENTS` - Optional rebase target (a bookmark or revset). Defaults to `trunk()`.

## Workflow

### 1. Check for uncommitted work

Run `jj status`. The working copy (`@`) is itself a commit, so there is nothing to stash — it rebases along with everything else. Just note whether `@` has changes so you can describe what moved.

### 2. Fetch from the remote

```bash
jj git fetch
```

This updates remote-tracking bookmarks (e.g. `main@origin`) without touching your local changes.

### 3. Identify the rebase target and what to move

- Target defaults to `trunk()` (resolves to the main bookmark on the remote). Use `$ARGUMENTS` if the user named a different target.
- Find your in-progress changes — the commits descending from the old trunk position. `jj log` shows the graph; the changes between trunk and `@` are what need replaying.

### 4. Rebase onto the updated trunk

```bash
jj rebase -o trunk()        # or the target from $ARGUMENTS
```

`-o`/`--onto` is the modern flag (`-d` is a legacy alias). jj rebases `@` and its ancestors that aren't already in the target, and rebases descendants automatically.

### 5. Handle conflicts (if any)

Conflicts do **not** stop the rebase — jj records them as data in the affected commits and continues. After rebasing:

```bash
jj log                # × marks conflicted commits
jj resolve --list     # conflicted paths in @
```

If anything is conflicted, resolve at the earliest conflicted ancestor (see `/jj-resolve`); descendants get fixed automatically when you fold the resolution back. Do not run a git mergetool — jj's conflict markers differ from git's.

### 6. Report the result

Show `jj log` and summarize: what trunk advanced to, which changes were replayed, and whether any conflicts remain to resolve.
