---
name: jj-push
description: Point a bookmark at the right change and push it to the remote
disable-model-invocation: true
---

# Jujutsu Push Workflow

Push your work to the remote. Unlike git, jj pushes **bookmarks**, not "the current branch" — so the key decision is which change the bookmark should point at before pushing.

## Arguments
- `$ARGUMENTS` - Optional bookmark name to push. If omitted, infer or prompt.

## Workflow

### 1. Find the change to push

Run `jj log`. The working copy `@` is usually an empty commit on top of your finished work, so the change to publish is typically `@-`, not `@`. Identify the topmost non-empty change the user wants on the remote.

### 2. Determine the bookmark

- **If a bookmark already tracks this line of work**, advance it to the target change:
  ```bash
  jj bookmark set <name> -r <change-id>
  ```
- **If there is no bookmark yet**, propose a name (from the change description or `$ARGUMENTS`) and create it the same way. Confirm the name with the user before creating.

Use `jj bookmark list` to see what already exists and where it points.

### 3. Preview what will be pushed

```bash
jj log -r <bookmark>
```

Confirm the bookmark points at the intended change and that the change has a real description (not "(no description set)"). If `@` is the empty tip, make sure the bookmark is on `@-`, not `@`.

### 4. Push

```bash
jj git push -b <bookmark>
```

`-b`/`--bookmark` pushes just that bookmark. jj refuses to push changes with empty descriptions or the placeholder author — fix those first if it complains.

### 5. Offer a PR (optional)

If the remote is GitHub and the user wants one, offer to open a PR with `gh pr create`. Otherwise just report the pushed bookmark and the remote it landed on.
