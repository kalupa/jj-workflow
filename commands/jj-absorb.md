---
name: jj-absorb
description: Auto-distribute working-copy edits into the ancestor commits that introduced those lines
disable-model-invocation: true
---

# Jujutsu Absorb Workflow

Take the changes in your working copy and push each hunk down into whichever mutable ancestor commit last touched those lines — automatically. `jj absorb` is jj's answer to a hand-built `git commit --fixup` + `rebase --autosquash`, with no analog you'd reach for in plain git.

## Arguments
- `$ARGUMENTS` - Optional paths to limit which files are absorbed. Defaults to all of `@`.

## Workflow

### 1. Show what's in the working copy

```bash
jj status
jj diff
```

These are the changes that will be redistributed. Absorb works best for small fixups that clearly belong to existing commits (a typo, a renamed symbol, a follow-up tweak) — not for genuinely new work.

### 2. Run absorb

```bash
jj absorb               # or: jj absorb <paths...>
```

jj walks the diff hunk by hunk and moves each one into the closest mutable ancestor that last modified those lines. Hunks it can't confidently attribute are **left in `@`**. Immutable commits (e.g. anything in `trunk()`) are never targeted.

### 3. Report what moved where

```bash
jj log
```

Summarize which commits absorbed which changes, and call out anything left behind in `@` that absorb couldn't place — those need a manual `jj squash --into <id>` or a fresh commit.

### 4. If it went wrong

```bash
jj undo
```

Reverses the absorb in one step, restoring all changes to `@`.

## When to use vs. not

- **Use it** when working-copy edits are fixups to commits that already exist in your stack.
- **Skip it** for new, standalone changes — those want `/jj-commit` instead.
- **Targeted alternative:** if you know the exact destination, `jj squash --into <change-id> [paths] -u` sends specific changes to one ancestor without absorb's guessing.
