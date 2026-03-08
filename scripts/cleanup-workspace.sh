#!/usr/bin/env bash
# Clean up a jj workspace after development work is done.
# Usage: cleanup-workspace.sh <workspace-name>

set -euo pipefail

WORKSPACE_NAME="${1:?Usage: cleanup-workspace.sh <workspace-name>}"

echo "Cleaning up workspace: $WORKSPACE_NAME"
echo ""

# Check if workspace exists
if ! jj workspace list | grep -q "^$WORKSPACE_NAME:"; then
  echo "Error: Workspace '$WORKSPACE_NAME' not found"
  echo ""
  echo "Active workspaces:"
  jj workspace list
  exit 1
fi

# Show what commits were made in this workspace
echo "Commits made in this workspace:"
jj log -r "$WORKSPACE_NAME@" --limit 5
echo ""

# Ask what to do
echo "Options:"
echo "  1. Delete workspace (commits remain in repo) [recommended]"
echo "  2. Move working copy changes to main workspace"
echo "  3. Cancel (keep workspace)"
read -p "Choice [1-3]: " choice

case "$choice" in
  1)
    jj workspace forget "$WORKSPACE_NAME"
    if [ -d "../$WORKSPACE_NAME" ]; then
      rm -rf "../$WORKSPACE_NAME"
    fi
    echo ""
    echo "Workspace deleted. Commits remain in repository."
    echo "In main workspace, use: jj new <commit-id> to build on those commits"
    ;;
  2)
    jj new "$WORKSPACE_NAME@" -m "Work from $WORKSPACE_NAME"
    jj workspace forget "$WORKSPACE_NAME"
    if [ -d "../$WORKSPACE_NAME" ]; then
      rm -rf "../$WORKSPACE_NAME"
    fi
    echo ""
    echo "Changes moved to new commit and workspace deleted."
    ;;
  3)
    echo "Cancelled — workspace kept."
    exit 0
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac
