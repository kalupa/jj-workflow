---
name: develop
description: Enter a jj workspace for isolated development work
disable-model-invocation: true
---

# Development Workspace

Enter a jj workspace for isolated development work. This keeps experimental changes separate from your main working copy.

## Arguments
- `$ARGUMENTS` - Feature name or description (optional, used for workspace naming)

## Workflow

### 1. Suggest workspace name

Based on the task description, suggest a name:
- Format: `claude-<feature>-YYYYMMDD` or `claude-dev-YYYYMMDD`
- Example: `claude-auth-refactor-20260307`
- Keep it short and descriptive

### 2. Enter workspace using EnterWorktree tool

Call the `EnterWorktree` tool with the suggested name. This triggers the WorktreeCreate hook which:
1. Creates a new jj workspace: `jj workspace add <name> --revision @`
2. Changes into the new directory
3. Creates a fresh empty change: `jj new @ -m "Work in <name>"`

### 3. Explain the workspace model

Tell the user:
- Their main workspace is untouched — they can continue other work there
- **Commits are shared** across workspaces (same underlying repository)
- **Working copy is isolated** — each workspace has its own `@` commit
- **No merging needed** — unlike git worktrees, jj commits are immediately visible everywhere

### 4. On completion

When work is done, remind the user:
- Commits are already in the repository (no merge/push needed between workspaces)
- Clean up with: `scripts/cleanup-workspace.sh <name>` (from the plugin) or `jj workspace forget <name>`
- The workspace directory can then be deleted

## Why No Manual Merging?

**Git worktrees** use separate branches that must be merged:
```bash
git checkout -b feature && git commit ...
git checkout main && git merge feature  # Manual merge!
```

**jj workspaces** share all commits — no merging:
```bash
jj workspace add dev --revision @
cd ../dev && jj new @ -m "Dev work"
# ... work and commit ...
cd ../default && jj log  # Commits already visible!
```

Key: jj workspaces share the same commit graph. Creating `jj new @` in a workspace gives it its own working copy while keeping main's `@` untouched.
