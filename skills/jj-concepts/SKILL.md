---
name: jj-concepts
description: Background knowledge about jujutsu (jj) version control for Claude
---

# Jujutsu (jj) Version Control Concepts

This project uses **jujutsu (jj)** instead of git. jj is a Git-compatible VCS with a different mental model. Always use `jj` commands, never `git`.

## Session Setup

At the start of any jj session, run:

```bash
jj config list
```

This reveals user-defined aliases, custom revset aliases, preferred diff tools, and default commands that change how jj behaves. Key things to look for:

- **`aliases.*`** — user shortcuts (e.g. `jj l`, `jj tug`). `jj tug` is a common community alias that moves the closest bookmark to `@-`. These may approximate newer built-ins — prefer built-in commands when both exist (e.g. `jj bookmark advance` supersedes `jj tug`).
- **`ui.default-command`** — what `jj` with no args shows. The value `["log", "-r", "(main..@):: | (main..@)-"]` (commits between main and @, plus siblings) is what jj itself suggests in its output, so it's common.
- **`ui.diff-formatter`** — may use an external tool like `difft` instead of built-in
- **`ui.paginate`** — if `"never"`, the `--no-pager` flag is redundant

## Self-Service Help (use this before guessing)

`jj` ships authoritative docs for its major subsystems. Prefer these over training-data recall when the question is about syntax or semantics:

```bash
jj help <subcommand>          # Per-command flags and usage
jj help -k <topic>            # Long-form documentation by keyword
```

Available `-k` topics and when to consult each:

| Topic | When to read |
|-------|--------------|
| `tutorial` | First exposure to jj concepts; conflict workflow walkthrough |
| `revsets` | Building any non-trivial `-r` expression beyond `@`, `@-`, `trunk()` |
| `templates` | Customizing `jj log` / `jj show` output formatting (`-T`) |
| `filesets` | Path/glob expressions used with file-aware commands |
| `bookmarks` | Local vs remote tracking, push semantics, divergence |
| `glossary` | Resolving unfamiliar terminology (e.g. "abandoned", "divergent", "hidden") |
| `config` | Settings keys, config file locations, scopes |

Run the relevant `jj help -k` topic when in doubt rather than guessing at flags or syntax.

## Terminology: "bookmark" is not "branch"

jj's vocabulary is deliberate. Use it precisely both in commands and when talking to the user — sloppy terminology produces sloppy commands.

- **Bookmark** — a named pointer to a commit. This is what git calls a "branch ref". Bookmarks are what you push, list, delete, and advance.
- **Branch** — in jj's own usage, refers to the *shape* of the commit graph: a chain of commits, whether or not anything is named. It is a topology word, not a name.
- **Anonymous branch** — a chain of commits with no bookmark on it or any descendant. jj keeps these around (they appear in `jj log`) until explicitly abandoned. This is a normal, named concept in jj — not a warning sign.

Practical consequences:

- When the user says "create a branch", they almost certainly mean a bookmark. Confirm by reaching for `jj bookmark create` / `jj bookmark set`, and use the word "bookmark" in the response.
- "Rebase this branch onto main" is fine — `branch` here is a topology, and `jj rebase -b <rev> -d main` handles it.
- Never write `jj branch …` in a command. There is no such subcommand; the verb is `jj bookmark`. A user who types `jj branch` is reaching for git muscle memory.
- **No "current bookmark."** Unlike git's HEAD-attached-to-branch model, `@` is not "on" a bookmark. New commits do not advance any bookmark. You move bookmarks explicitly with `jj bookmark set` / `move` / `advance`, or implicitly via `jj git push` after a rewrite (rewrites are followed by change ID).
- In a **colocated** workspace (jj alongside `.git/`), each git branch corresponds to a jj bookmark of the same name. That's an implementation bridge, not a conceptual equivalence — keep using "bookmark" when describing user-facing operations.

## Mental Model

### The working copy is always a commit
`@` is a real commit, not a staging area. Every file edit automatically amends `@`. No `git add` needed — just edit files.

### Change IDs are stable; commit IDs are not
Every commit has two identifiers: a **change ID** (e.g. `kzomqsrt`) that stays the same across rewrites, and a **commit ID** (hash) that changes. Always use change IDs when targeting specific commits — they survive rebases, amends, and squashes. The tutorial says: *"We will generally prefer change IDs because they stay the same when the commit is rewritten."*

### History is freely rewritable
`jj edit <change-id>` makes any past commit the working copy. Descendants auto-rebase. You can fix a bug five commits ago without stashing, branching, or cherry-picking.

### Conflicts are data, not blocking states
Conflicts are stored inside commits. A rebase that produces conflicts still succeeds — the conflicted state is committed and you resolve it later. `jj log` marks conflicted commits with `×`.

### Commits are immutable — rewrites create new commits
There is no true "amend" in jj. Every rewrite (describe, squash, rebase) creates a new commit ID while preserving the change ID. jj prevents rewriting commits that are in the immutable set (typically anything merged to `main`/`trunk()`). Use `--ignore-immutable` as a last resort escape hatch, but prefer rebasing on top instead.

### The operation log is your safety net
Every jj command is recorded. `jj undo` reverts the last operation — not just the last commit, but any operation including rebases, squashes, and pushes. Much simpler than `git reset` variants.

## Inspecting Changes

```bash
jj show                    # Commit metadata + full diff — prefer over status+diff (one command)
jj status                  # Changed filenames only (use when diff would be too large)
jj diff                    # Full diff without commit metadata
jj show <change-id>        # Show a specific commit
jj log                     # Recent commits (graph view)
jj log -r 'all()'          # All commits
jj log -r '..@'            # Everything up to working copy
jj evolog                  # How the current change evolved over time
```

## Creating and Editing Commits

```bash
jj new -m "msg"            # New empty commit with description (no editor)
jj new <change-id> -m "msg"  # New commit on top of a specific revision
jj commit -m "msg"         # Finalize @ with message, create new empty @
jj commit -m "msg" f1 f2   # Commit only specific files
jj describe -m "msg"       # Set/change description of @ without finalizing
jj edit <change-id>        # Make any commit the working copy (descendants auto-rebase)
jj abandon <change-id>     # Drop a commit; descendants rebase to its parent
```

**Always use `-m "..."` with any commit-like command — without it, an editor opens.**

## Moving Changes Between Commits

```bash
jj squash -m "msg"                          # Move all of @ into parent
jj squash file1 file2 -m "msg"             # Move specific files into parent
jj squash --from <id> --into <id> -m "msg" # Move changes between any two commits
jj squash -u                               # Use destination's message (no editor)
jj split file1 file2 -m "msg"             # Split: listed files → first commit, rest stay
```

**`jj squash` and `jj split` open an editor by default** (when descriptions need to be combined, or when no filesets are given). Avoid this by always providing filesets and `-m`.

`jj diffedit` always opens an interactive diff editor — avoid it. Instead:
- Move whole files: `jj restore <files> --from <id>`
- Move specific changes: edit files directly with your editor, then `jj squash <files>`

`jj restore` is also useful for reverting a file to its state in a specific revision without creating a new commit — the change lands in `@` as an uncommitted edit:

```bash
jj restore <file>                    # Restore file to parent's state (discard edits)
jj restore <file> --from <change-id> # Restore file to any revision's state
```

This is preferable to manually editing a file back to a known state.

## Rebasing

`jj rebase` takes one of three source selectors plus a destination. They are not interchangeable:

| Flag | Moves | Mnemonic |
|------|-------|----------|
| `-r <rev>` | just that one commit | "this revision only" — descendants stay put, get rebased onto its old parent |
| `-s <rev>` | `<rev>` and all descendants | "source subtree" |
| `-b <rev>` | the whole branch containing `<rev>` that isn't yet in the destination | "branch" |

Destinations:

| Flag | Meaning |
|------|---------|
| `-d <rev>` | New parent (most common) |
| `-A <rev>` | Insert *after* `<rev>` (between it and its current children) |
| `-B <rev>` | Insert *before* `<rev>` |

```bash
jj rebase -s <feature> -d main         # Move feature stack onto main
jj rebase -r <fix> -A <target>         # Reorder: move <fix> to sit after <target>
jj rebase -b @ -d main@origin          # Update local stack onto fetched main
```

Rebase never blocks on conflicts — see Resolving Conflicts below.

## Commands a git user will miss (don't fall back to git habits)

These are first-class jj commands that replace multi-step git workflows. Reach for these before composing the same effect from `jj rebase` + `jj squash` + `jj new`.

- **`jj absorb`** — distributes the working-copy changes into the ancestor commits that last modified the same lines. Replaces `git commit --fixup` + `git rebase -i --autosquash` in one command. Targets `mutable()` by default; restrict with `--into <revset>` or `[filesets...]`.
- **`jj fix`** — runs configured formatters (`[fix.tools]`) on the changed files of one or more revisions, then propagates results to descendants without producing conflicts. Replaces `format && git commit --amend && rebase`.
- **`jj duplicate -r <rev> [-A|-B|-d <dest>]`** — copies a commit's content as a new change. The canonical "cherry-pick" replacement.
- **`jj revert -r <rev> -d <dest>`** — applies the inverse of `<rev>` at `<dest>`. (The old `jj backout` no longer exists.) `-A`/`-B` insertion flags also work.
- **`jj interdiff --from <a> --to <b>`** — diffs the *diffs* of two revisions. Use it to see what changed between two iterations of the same change (e.g. before vs after a force-push: `jj interdiff --from push-xyz@origin --to push-xyz`). Not the same as `jj diff --from --to`, which compares file contents.
- **`jj metaedit -r <rev>`** — change author/email/timestamp without touching content. Use `--update-change-id` to detach a copy from the original change ID.
- **`jj parallelize <revset>`** — turn a linear chain into siblings sharing the same parent. Inverse: `jj rebase` them back into a line.
- **`jj simplify-parents -r <rev>`** — remove redundant parents from a merge commit when one parent is an ancestor of another.
- **`jj file <subcmd>`** — `list`, `show <file>`, `annotate <file>` (blame), `track <pat>`, `untrack <pat>`, `chmod {n|x} <file>`. Prefer these over shelling out to `cat`/`chmod` when you want the working-copy snapshot semantics.

## Resolving Conflicts

Conflicts in jj are stored *inside* commits, so `jj rebase` always succeeds. The conflicted commit gets an `×` marker in `jj log`.

```bash
jj resolve --list              # List conflicted files
jj resolve --tool :ours        # Non-interactive: accept side 1
jj resolve --tool :theirs      # Non-interactive: accept side 2
```

For custom resolution: **edit the conflict markers directly in the file**. jj auto-detects the resolution on the next command — no need to run `jj resolve` at all.

Standard workflow:
```bash
jj new <conflicted-change-id>              # Create a child of the conflicted commit
# edit the file to resolve conflicts
jj squash -m "resolve conflict in <file>"  # Squash resolution into the conflicted commit
```

**jj's conflict markers are not git's.** They include a `%%%%%%% diff` block showing how one side evolved relative to the merge base, and a `+++++++` block holding the literal content of the other side. See `references/conflicts.md` for the marker format and worked examples before editing a jj conflict by hand.

## Operation Log (Safety Net)

```bash
jj op log                       # List all operations
jj undo                         # Undo the last operation (any operation, not just commits)
jj redo                         # Redo the last undone operation
jj op show <op-id>              # Inspect what a specific operation changed
jj op restore <op-id>           # Hard-reset the whole repo to a past op (destructive)
jj --at-operation <op-id> <cmd> # Run any read-only command against a past repo state
```

`jj undo` is the answer to almost any mistake. Much simpler than `git reset --hard`, `git reflog`, etc. `--at-operation` (alias `--at-op`) is the read-only time machine — use it to inspect what the repo looked like before a problematic operation without modifying anything.

## Bookmarks (vs Git Branches)

Bookmarks map to git branches when pushing, but work differently:

**Key differences from git branches:**
- **No "current bookmark"** — `@` is not "on" a bookmark. Bookmarks are just labels pointing at commits, not a current location.
- **Bookmarks don't move on commit** — in git, committing advances the current branch. In jj, bookmarks stay put. You move them explicitly.
- **Remote tracking is visible** — `bookmark@origin` is a separate ref. After fetching, you can see local and remote diverge before pushing.
- **Moving backwards requires a flag** — `jj bookmark move name --allow-backwards` (unlike `git branch -f`).
- **Deletion is two-step** — delete locally, then push the deletion separately.

```bash
jj bookmark create <name> -r <change-id>  # Create at specific commit
jj bookmark set <name>                     # Point bookmark to @
jj bookmark move <name> --to <change-id>  # Move to any commit (only existing bookmarks)
jj bookmark move <name> --to <id> --allow-backwards  # Move to an ancestor
jj bookmark advance                          # Advance closest bookmark(s) to @
jj bookmark advance <name>                   # Advance specific bookmark to @
jj bookmark advance <name> --to <change-id>  # Advance specific bookmark to target
jj bookmark list --all                     # List local + remote tracking bookmarks
jj bookmark delete <name>                  # Mark deleted locally
jj git push --bookmark <name>             # Push a specific bookmark
jj git push --deleted                     # Propagate local deletions to remote
jj git push                               # Push all changed bookmarks
jj git fetch                              # Fetch from remote
```

**No `--force` needed after rewrites.** `jj git push` handles rewritten history transparently — it reports "Move sideways bookmark" and force-pushes implicitly. Unlike git, there is no `--force-with-lease` muscle memory to invoke. jj tracks change IDs separately from commit IDs, so it knows the rewrite was intentional.

**`bookmark move` vs `bookmark advance`:**
- `move` — explicit: you say exactly where the bookmark goes
- `advance` — without args, finds the closest bookmark(s) that are ancestors of `@` and moves them forward to `@`; with a name, advances that specific bookmark to `@`; useful after squashing/rebasing when the bookmark is lagging behind your work

**Bookmark operations do not affect `@`** — unlike `git checkout <branch>` which moves HEAD and updates the working tree, moving or advancing a bookmark in jj is purely administrative. The working copy stays exactly where it is.

## Workspace Model

jj workspaces are like git worktrees but better:
- Each workspace has its own `@` (working copy)
- All workspaces share the same commit graph — no merging needed
- Create: `jj workspace add <name> --revision @`
- Remove: `jj workspace forget <name>`

## Revset Syntax

| Symbol | Meaning |
|--------|---------|
| `@` | Current working copy commit |
| `@-` | Parent of working copy |
| `trunk()` | Main branch tip (remote main/master) |
| `mine()` | Commits authored by you |
| `bookmarks()` | All bookmarked commits |
| `foo-` | Parent of foo |
| `foo+` | Children of foo |
| `::foo` | Ancestors of foo |
| `foo::bar` | DAG range |
| `foo..bar` | Range (like git's) |

Prefer change IDs over relative refs like `@-` when targeting specific commits — change IDs are stable across rewrites, relative refs shift as the working copy moves.

## Reference

- **`references/git-to-jj.md`** — comprehensive git-to-jj command mapping
- **`references/conflicts.md`** — jj's conflict marker format and resolution recipes
- **`references/revsets.md`** — curated revset language: operators, common functions, idioms
- **`references/filesets.md`** — curated fileset language for file-aware commands
- **In-tree `jj help -k <topic>`** — authoritative docs for revsets, templates, filesets, bookmarks, config, glossary, tutorial
