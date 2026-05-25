---
name: jj-resolve
description: Walk through resolving jj conflicts, which are stored as data in commits
disable-model-invocation: true
---

# Jujutsu Conflict Resolution Workflow

Resolve conflicts in a jj repo. jj treats conflicts as **data recorded in commits** — they don't block operations and they persist until cleared. See `skills/jj-concepts/references/conflicts.md` for the full marker format; this command is the step-by-step.

## Arguments
- `$ARGUMENTS` - Optional change ID to resolve. Defaults to the conflicted commit(s) shown in `jj log`.

## Workflow

### 1. Locate the conflicts

```bash
jj log                # × marks conflicted commits
jj resolve --list     # conflicted paths in @
```

If conflicts live in an ancestor (not `@`), resolve at the **earliest** conflicted commit — descendants get fixed automatically when you fold the resolution back.

### 2. Choose a resolution strategy

- **Conflict is in `@`** → edit the file in place (step 3A).
- **Conflict is in a non-`@` commit** → resolve in a child, then squash back (step 3B). This is jj's recommended workflow.
- **One side wins wholesale** (e.g. a generated file) → take a side non-interactively (step 3C).

### 3. Resolve

**3A — in `@`:** Open each conflicted file. Replace the entire `<<<<<<< … >>>>>>>` block (fences included) with the final content. Remember jj's marker format: the `%%%%%%%` block is a *base→side* diff, the `+++++++` block is the other side's literal content. Leave **no** fence or separator lines behind. Then:
```bash
jj status   # re-snapshots; conflict clears when markers are gone
```

**3B — in a child, then fold back:**
```bash
jj new <conflicted-change-id>              # child inherits the conflict
# edit files, remove all markers
jj squash -u                               # fold resolution back (-u reuses parent message)
```
The message guard hook requires `-m` or `-u` on `squash` — `-u` reuses the destination message, which is what you want here.

**3C — take one side:**
```bash
jj resolve --tool :ours <file>     # keep side 1
jj resolve --tool :theirs <file>   # keep side 2
```

### 4. Verify

```bash
jj resolve --list   # should report no conflicts
jj log              # × markers gone
```

If you resolved wrong, `jj undo` reverses the last resolve/squash.

## Pitfalls

- **Never run a git mergetool.** jj's `%%%%%%%`/`+++++++` markers are not git's `<<<<<<<`/`=======`/`>>>>>>>` — a git tool will silently corrupt them.
- **Conflicts propagate, they don't stop.** A rebase over a conflict makes more conflicted commits rather than halting. Fix the earliest ancestor and let `jj squash` repair descendants.
