# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`jj-workflow` is a Claude Code **plugin** (not application code). It teaches Claude to use [jujutsu (jj)](https://martinvonz.github.io/jj/) instead of git. There is no build, no test suite, and no package manager — components are loaded directly by Claude Code from the manifest.

This repo is itself managed with jj. Use `jj` commands, never `git`. The `block-git.sh` hook will reject `git` commands when run inside Claude Code here.

## Architecture

Four component types, wired together by `.claude-plugin/plugin.json` and `hooks/hooks.json`:

1. **Hooks** (`hooks/hooks.json` + `hooks/scripts/*.sh`) — the enforcement layer.
   - `block-git.sh`: `PreToolUse` on `Bash`. Reads tool-input JSON from stdin, walks up from `pwd` looking for `.jj/`; if found, maps the git subcommand to its jj equivalent and exits 2 to block. Exits 0 (pass-through) otherwise. **This is what makes the plugin work** — every other component assumes git is unavailable.
   - `guard-jj-message.sh`: `PreToolUse` on `Bash`. Blocks `jj split|squash|commit` without `-m`/`--message` (or `-u` for squash) to prevent Claude from getting stuck in an interactive editor.
   - `WorktreeCreate` / `WorktreeRemove`: bridge Claude Code's worktree mechanism to `jj workspace add` / `jj workspace forget`. jj workspaces share one commit graph, so no merge is needed when work completes.

2. **Slash commands** (`commands/*.md`) — `/jj-commit` (selective file grouping + commit, runs optional `.claude/jj-pre-commit.sh` from the host project) and `/develop` (enter a jj workspace via the `EnterWorktree` mechanism). Both have `disable-model-invocation: true` — Claude only runs them when the user types the slash command.

3. **Skill** (`skills/jj-concepts/SKILL.md` + `references/`) — background knowledge auto-loaded when jj work is happening. Documents the jj mental model (working copy is a commit, change IDs vs commit IDs, conflicts as data, immutable set).

4. **Script** (`scripts/cleanup-workspace.sh`) — user-invoked workspace teardown helper.

### Key design facts to preserve when editing

- Hook scripts parse stdin JSON with `python3 -c "import sys,json; ..."`. Keep this — it avoids a `jq` dependency.
- `block-git.sh` detects "is this a jj repo?" by walking up for `.jj/`, **not** by calling `jj`. This makes it cheap and safe when jj isn't installed in the host project.
- Hook commands in `hooks.json` reference scripts via `${CLAUDE_PLUGIN_ROOT}`. Don't hardcode paths.
- The git→jj mapping table lives in `block-git.sh`. When adding a mapping, also consider whether the `jj-concepts` skill needs the same entry.

## Common tasks

- **Install locally for testing**: `/plugin marketplace add kalupa/jj-workflow` then `/plugin install jj-workflow@jj-workflow` from Claude Code.
- **Test a hook script manually**: `echo '{"command":"git status"}' | bash hooks/scripts/block-git.sh; echo "exit=$?"` (run from inside a directory with a `.jj/`).
- **Inspect plugin wiring**: `cat .claude-plugin/plugin.json hooks/hooks.json`.

There is no lint or test command. Validate changes by exercising the hook/command in a real Claude Code session.
