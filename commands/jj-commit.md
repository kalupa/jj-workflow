---
name: jj-commit
description: Create a focused jujutsu commit with selective file grouping
disable-model-invocation: true
---

# Jujutsu Commit Workflow

Create focused jj commits with related changes only. Unlike git, jj has no staging area — the working copy IS the current commit (@).

## Arguments
- `$ARGUMENTS` - Commit message (optional, will prompt if not provided)

## Workflow

### 1. Show changed files grouped by category

Run `jj status` and group files into categories:
- **Scripts**: `*.sh`, `*.hs`, `*.py`, `bin/*`
- **Config**: `*.conf`, `*.toml`, `*.yaml`, `*.yml`, `*.json`, `CLAUDE.md`, `.claude/*`
- **Data**: `*.journal`, `*.csv`, `*.rules`, `*.ledger`, `*.beancount`
- **Docs**: `*.md` (excluding CLAUDE.md), `*.txt`, `*.rst`
- **Other**: Everything else

**Output format:**
```
Changed files by category:

  [1] Scripts (2 files)
      bin/fetch-prices.sh
      hledger-factset-paystub.hs

  [2] Config (1 file)
      CLAUDE.md
```

### 2. Select files to commit

**If only ONE category has changes:**
- Auto-select that category, show preview, ask to confirm

**If MULTIPLE categories have changes:**
- Use `AskUserQuestion` with **multiSelect: true**
- Each option: category name + file count, description lists the files

### 3. Pre-commit validation

Check for `.claude/jj-pre-commit.sh` in the project root:
- If it exists and is executable, run it
- If it fails (non-zero exit), BLOCK the commit and show the output
- If it doesn't exist, skip this step

This allows projects to add custom validation (e.g., `hledger check`, `cargo test`, `npm run lint`) without modifying the plugin.

### 4. Create commit with selected files

```bash
# Commit only the selected files
jj commit -m "<message>" <file1> <file2> ...

# Other files remain in working copy (@) for future commits
```

### 5. Show commit result

```bash
jj log -r @ -r @-
```

### 6. Remind about bookmark advancement

After the commit, remind:
```
Tip: Run `jj bookmark advance` (or `jj ba`) to move bookmarks forward.
```

## Key Differences from Git

| Aspect | Git | Jujutsu (jj) |
|--------|-----|--------------|
| Staging | `git add` required | No staging — working copy is @ commit |
| Selective commit | Stage files, then commit | `jj commit [paths...]` directly |
| Uncommitted changes | Outside staging area | Remain in working copy (@) |
| Commit all | `git commit -a` | `jj commit` (no paths) |
