# jj Conflict Marker Format and Resolution

jj writes conflicts to files using a different syntax than git. Editing a conflict as if it were a git conflict will corrupt it.

## The marker format

A two-sided conflict looks like this (from the jj tutorial):

```
<<<<<<< Conflict 1 of 1
%%%%%%% Changes from base to side #1
-b1
+a
+++++++ Contents of side #2
b2
>>>>>>> Conflict 1 of 1 ends
```

Anatomy:

- `<<<<<<<` / `>>>>>>>` — outer fences, one per conflict region.
- `%%%%%%%` block — a **diff** showing how one side changed relative to the merge base. Lines starting with `-` were in the base, `+` lines replaced them, unprefixed lines are unchanged context.
- `+++++++` block — the **literal** content of the other side. No diff syntax; whatever is here is taken verbatim.

The `%%%%%%%` and `+++++++` blocks may be labeled with which revision contributed them (e.g. `parents of rebased revision` → `rebase destination`, or `Contents of side #N`). Trust the labels — they identify which change is on which side.

There can be more than two sides (an N-way conflict) — additional `%%%%%%%` / `+++++++` blocks appear between the fences, one per side beyond the first.

## How resolution actually happens

jj does not require running `jj resolve`. It snapshots the working copy on every command; the moment the file no longer contains conflict markers, the conflict is considered resolved and the working copy commit becomes non-conflicted.

To resolve by hand:

1. Open the file.
2. Replace the entire `<<<<<<< ... >>>>>>>` block (fences included) with the final intended content.
3. Run any jj command (e.g. `jj status`). jj re-snapshots and clears the conflict.

Do **not** leave any of the fence lines, the `%%%%%%%`/`+++++++` separators, or stray base-diff lines in the file. They are not comments — they are part of the conflict serialization, and leaving them in means the conflict is unresolved.

## Resolution workflows

### A. Resolve in the conflicted commit itself

If the conflict is in `@` and you want to fix it in place:

```bash
# edit the file, remove markers
jj status   # confirms conflict cleared
```

### B. Resolve in a child commit, then fold back (recommended for non-@ conflicts)

This is what the tutorial demonstrates and what jj's own hint suggests:

```bash
jj new <conflicted-change-id>              # child commit with conflict inherited
# edit the file, remove markers
jj squash -m "resolve conflict in <file>"  # fold the resolution back
```

`jj squash` will rebase descendants automatically and report `Existing conflicts were resolved or abandoned from N commits.`

### C. Take one side wholesale

```bash
jj resolve --tool :ours <file>     # keep side 1
jj resolve --tool :theirs <file>   # keep side 2
```

These are non-interactive and safe in scripts. Useful when one side is a generated file or you've already decided.

### D. List what's outstanding

```bash
jj resolve --list                   # all conflicted paths in @
```

## Pitfalls

- **Don't run a git mergetool.** Tools that understand git's `<<<<<<<`/`=======`/`>>>>>>>` will not parse jj's `%%%%%%%`/`+++++++` blocks correctly and may silently keep half the conflict in the file.
- **Read the `%%%%%%%` diff direction carefully.** It is *base → side*, not *side → side*. A `-` line was in the merge base and was removed by that side; a `+` line is what that side put in its place.
- **Conflicts propagate but don't block.** A `jj rebase` over a conflict will produce more conflicted commits, not stop. Resolve at the earliest conflicted ancestor and let the descendants get fixed automatically by `jj squash`.
- **`jj undo` reverses a resolution.** If you squashed a wrong resolution back, `jj undo` restores the conflicted state — no reflog gymnastics needed.

## Quick reference

```bash
jj log                                          # × marks conflicted commits
jj resolve --list                               # list conflicted paths
jj resolve --tool :ours <file>                  # take side 1
jj resolve --tool :theirs <file>                # take side 2
jj new <id> && $EDITOR <file> && jj squash -u   # manual resolve + fold back (reuse parent message)
jj undo                                         # back out the last resolve/squash
```
