#!/usr/bin/env bash
# guard-jj-message.sh — Blocks jj split/squash/commit without -m to prevent editor opening.
# Called as a PreToolUse hook for Bash. Reads tool input JSON from stdin.
# Exit 0 = allow, Exit 2 = block with message.

set -euo pipefail

COMMAND=$(python3 -c "import sys,json; print(json.load(sys.stdin).get('command',''))" 2>/dev/null)

# Only intercept jj commands
case "$COMMAND" in
  jj\ *) ;;
  *) exit 0 ;;
esac

# Only check commands that open an editor without a message flag
jj_subcmd=$(echo "$COMMAND" | awk '{print $2}')
case "$jj_subcmd" in
  split|squash|commit) ;;
  *) exit 0 ;;
esac

# Allow if a message flag is present
# squash also accepts -u/--use-destination-message to skip the editor
if echo "$COMMAND" | grep -qE -- '-m\b|--message\b|-u\b|--use-destination-message\b'; then
  exit 0
fi

echo "BLOCK: 'jj $jj_subcmd' without -m will open an interactive editor."
echo "  Always provide: jj $jj_subcmd -m \"your message\" ..."
if [ "$jj_subcmd" = "squash" ]; then
  echo "  Or use -u (--use-destination-message) to reuse the destination's message."
fi
exit 2
