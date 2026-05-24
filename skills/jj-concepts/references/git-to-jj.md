# Git to Jujutsu Command Mapping

## Basic Operations

| Git | Jujutsu (jj) | Notes |
|-----|-------------|-------|
| `git status` | `jj status` | Shows working copy changes and conflicts |
| `git diff` | `jj diff` | Diff of working copy vs parent |
| `git diff --staged` | *(no equivalent)* | No staging area in jj |
| `git diff HEAD~2` | `jj diff -r @--` | Diff against grandparent |
| `git diff A...B` | `jj diff -r A..B` | Diff across a revision range |
| `git log` | `jj log` | Default shows recent personal commits |
| `git log --oneline` | `jj log --no-graph` | Compact log |
| `git show <rev>` | `jj show <rev>` | Show commit details |
| `git blame <file>` | `jj file annotate <file>` | Per-line attribution |

## Staging and Committing

| Git | Jujutsu (jj) | Notes |
|-----|-------------|-------|
| `git add <file>` | *(not needed)* | Working copy IS the commit |
| `git add -A` | *(not needed)* | All changes are already tracked |
| `git commit -m "msg"` | `jj commit -m "msg"` | Finalizes @, creates new empty @ |
| `git commit -am "msg"` | `jj commit -m "msg"` | Same — no staging needed |
| `git commit --amend` | `jj describe -m "msg"` | Change message of @ |
| `git commit --amend` | `jj squash` | Fold @ into parent |

## Selective Commits

| Git | Jujutsu (jj) | Notes |
|-----|-------------|-------|
| `git add f1 f2 && git commit` | `jj commit -m "msg" f1 f2` | Commit specific files only |
| `git add f1 f2 && git commit --amend` | `jj squash f1 f2 -u` | Fold only those files into the parent (`-u` keeps the parent's message; the message guard hook requires `-m`/`-u`) |
| `git add f1 && git commit --fixup=X` | `jj squash --into X f1 -u` | Send only those files to a specific ancestor |
| `git add -p` | `jj split` | Interactive split of changes |
| `git reset HEAD <file>` | *(not needed)* | No staging to unstage from |
| `git stash` | `jj new` then `jj edit @-` | Leave changes in a commit, work elsewhere |
| `git stash pop` | `jj edit <stashed>` | Go back to the commit with changes |

## Branches and Navigation

| Git | Jujutsu (jj) | Notes |
|-----|-------------|-------|
| `git branch <name>` | `jj bookmark set <name>` | Create/move bookmark |
| `git branch -d <name>` | `jj bookmark delete <name>` | Delete bookmark |
| `git branch -a` | `jj bookmark list --all` | List all bookmarks |
| `git checkout <branch>` | `jj new <bookmark>` | Create new change at bookmark |
| `git switch <branch>` | `jj new <bookmark>` | Same as checkout |
| `git checkout -b <name>` | `jj new` then `jj bookmark set <name>` | New change + bookmark |
| *(advance branch)* | `jj bookmark advance` / `jj ba` | Move bookmarks forward |

## History Editing

| Git | Jujutsu (jj) | Notes |
|-----|-------------|-------|
| `git rebase <target>` | `jj rebase -o <target>` | Rebase onto target (`-o`/`--onto`; `-d` is a legacy alias) |
| `git rebase -i` (reorder) | `jj rebase -r C --before B` | Non-interactive reorder. `jj arrange` exists but opens an interactive TUI — avoid it. |
| `git commit --fixup=X && git rebase --autosquash X^` | `jj squash --into X [files]` | Fold specific changes into a known ancestor in one step |
| `git reset --hard` | `jj restore` | Restore working copy to parent |
| `git reset --hard <rev>` | `jj restore --from <rev>` | Restore to specific revision |
| `git reset --soft HEAD~` | *(no direct equivalent — see note below)* | No staging area; reshape in place or `jj squash --from @-` |
| `git revert <rev>` | `jj revert -r <rev> -o @` | Create inverse commit at destination (`-A`/`-B` also work). The old `jj backout` no longer exists. |
| `git cherry-pick <rev>` | `jj duplicate -r <rev> -o @` | Single command — `-A <after>` / `-B <before>` / `-o <onto>` pick the destination. |

### On `git reset --soft` (there is no jj equivalent)

`git reset --soft HEAD~` means "uncommit the last commit but keep its changes around so I can recompose them." jj has **no index/staging area**, so there's nothing to reset *into* — the operation doesn't translate as a single command. Reach for the intent instead:

- **Usually you don't uncommit at all.** Commits are mutable, so reshape in place: `jj describe` (change the message), `jj split` (break a commit apart), `jj squash` (combine commits). You rarely need to "undo a commit to redo it."
- **If you genuinely want the previous commit's changes back in your working copy:** `jj squash --from @-`. This folds `@-`'s changes down into `@` (the default `--into` target is the working copy), collapsing that commit boundary.

This mirrors how `git add` and `git stash` map to "not needed" above — the git habit assumes a staging area that jj doesn't have.

## Remote Operations

| Git | Jujutsu (jj) | Notes |
|-----|-------------|-------|
| `git push` | `jj git push` | Push bookmarks to remote |
| `git push -u origin <b>` | `jj git push -b <bookmark>` | Push specific bookmark |
| `git pull` | `jj git fetch` then `jj rebase` | Fetch + rebase separately |
| `git fetch` | `jj git fetch` | Fetch from remote |
| `git clone <url>` | `jj git clone <url>` | Clone repository |
| `git remote add <name> <url>` | `jj git remote add <name> <url>` | Add a named remote |

## Workspace (Worktree) Operations

| Git | Jujutsu (jj) | Notes |
|-----|-------------|-------|
| `git worktree add <path>` | `jj workspace add <name>` | Shared commit graph, no merge needed |
| `git worktree remove <path>` | `jj workspace forget <name>` | Commits remain in repo |
| `git worktree list` | `jj workspace list` | List active workspaces |

## File Operations

| Git | Jujutsu (jj) | Notes |
|-----|-------------|-------|
| `git mv <old> <new>` | `mv <old> <new>` | jj auto-detects renames |
| `git rm <file>` | `jj file untrack <file>` | Stop tracking file |
| `git checkout -- <file>` | `jj restore <file>` | Discard changes to file |

## Inspection

| Git | Jujutsu (jj) | Notes |
|-----|-------------|-------|
| `git log --graph` | `jj log` | Graph is default in jj |
| `git log -p` | `jj log -p` | Log with patches |
| `git log -G <pat>` (pickaxe) | `jj log -r 'diff_lines(regex:<pat>)'` | Find commits whose diff touches a pattern |
| `git reflog` | `jj op log` | Repo-wide history of operations / undo timeline |
| *(how did this commit evolve?)* | `jj evolog` | Per-change evolution across rewrites (modern name; `obslog` is a kept alias) |
| `git log main..HEAD` | `jj log -r @::trunk()` | Revset range |
| `git ls-files` | `jj file list` | List tracked files in the working copy |
| `git grep <pat>` | `rg --no-require-git <pat>` or `grep <pat> $(jj file list)` | Search tracked content (no `git grep` equivalent) |
| `git rev-parse --show-toplevel` | `jj workspace root` | Absolute path to the workspace root |
