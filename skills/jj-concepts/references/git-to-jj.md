# Git to Jujutsu Command Mapping

## Basic Operations

| Git | Jujutsu (jj) | Notes |
|-----|-------------|-------|
| `git status` | `jj status` | Shows working copy changes and conflicts |
| `git diff` | `jj diff` | Diff of working copy vs parent |
| `git diff --staged` | *(no equivalent)* | No staging area in jj |
| `git diff HEAD~2` | `jj diff -r @--` | Diff against grandparent |
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
| `git rebase <target>` | `jj rebase -d <target>` | Rebase onto target |
| `git rebase -i` | `jj rebase` + `jj squash` + `jj split` | Combine operations |
| `git reset --hard` | `jj restore` | Restore working copy to parent |
| `git reset --hard <rev>` | `jj restore --from <rev>` | Restore to specific revision |
| `git revert <rev>` | `jj backout -r <rev>` | Create inverse commit |
| `git cherry-pick <rev>` | `jj new <rev>` then `jj squash` | Copy commit's changes |

## Remote Operations

| Git | Jujutsu (jj) | Notes |
|-----|-------------|-------|
| `git push` | `jj git push` | Push bookmarks to remote |
| `git push -u origin <b>` | `jj git push -b <bookmark>` | Push specific bookmark |
| `git pull` | `jj git fetch` then `jj rebase` | Fetch + rebase separately |
| `git fetch` | `jj git fetch` | Fetch from remote |
| `git clone <url>` | `jj git clone <url>` | Clone repository |

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
| `git reflog` | `jj obslog` | Operation/evolution log |
| `git log main..HEAD` | `jj log -r @::trunk()` | Revset range |
