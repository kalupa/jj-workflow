#!/usr/bin/env bash
# block-git.sh — Intercepts git commands in jj repos and suggests jj equivalents.
# Called as a PreToolUse hook for Bash. Reads tool input JSON from stdin.
# Exit 0 = allow, Exit 2 = block with message.

set -euo pipefail

# Extract the command from stdin JSON
COMMAND=$(python3 -c "import sys,json; print(json.load(sys.stdin).get('command',''))" 2>/dev/null)

# Only intercept commands starting with "git "
case "$COMMAND" in
  git\ *) ;;
  *) exit 0 ;;
esac

# Walk up directory tree looking for .jj/ (are we in a jj repo?)
check_dir="$(pwd)"
found_jj=false
while [ "$check_dir" != "/" ]; do
  if [ -d "$check_dir/.jj" ]; then
    found_jj=true
    break
  fi
  check_dir="$(dirname "$check_dir")"
done

if [ "$found_jj" = false ]; then
  # Not a jj repo — allow git commands
  exit 0
fi

# Extract git subcommand
git_subcmd=$(echo "$COMMAND" | awk '{print $2}')

# Map git subcommand to jj equivalent
case "$git_subcmd" in
  status)      jj_equiv="jj status" ;;
  diff)        jj_equiv="jj diff" ;;
  log)         jj_equiv="jj log" ;;
  commit)      jj_equiv="jj commit" ;;
  add)         jj_equiv="(not needed — jj has no staging area, working copy is the commit)" ;;
  branch)      jj_equiv="jj bookmark" ;;
  checkout)    jj_equiv="jj new" ;;
  switch)      jj_equiv="jj new" ;;
  merge)       jj_equiv="jj new <rev1> <rev2> (create merge commit)" ;;
  rebase)      jj_equiv="jj rebase" ;;
  reset)       jj_equiv="jj restore" ;;
  stash)       jj_equiv="(not needed — jj commit and jj new handle this)" ;;
  push)        jj_equiv="jj git push" ;;
  pull)        jj_equiv="jj git fetch" ;;
  fetch)       jj_equiv="jj git fetch" ;;
  clone)       jj_equiv="jj git clone" ;;
  init)        jj_equiv="jj git init" ;;
  show)        jj_equiv="jj show" ;;
  tag)         jj_equiv="jj tag" ;;
  cherry-pick) jj_equiv="jj new <rev> (then jj squash)" ;;
  blame)       jj_equiv="jj file annotate" ;;
  restore)     jj_equiv="jj restore" ;;
  mv)          jj_equiv="jj file track (after moving)" ;;
  rm)          jj_equiv="jj file untrack" ;;
  *)           jj_equiv="(check jj --help for equivalent)" ;;
esac

echo "BLOCK: This is a jj repository. Use jj instead of git."
echo "  git $git_subcmd → $jj_equiv"
exit 2
