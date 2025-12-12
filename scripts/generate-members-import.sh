#!/bin/bash

# Generate users-import.tf with import blocks for GitHub users
# Usage: ./generate-users-import-tf.sh

set -e

ORG_NAME="rsi-pf-eng-sandbox"

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed" >&2
    echo "Please install it from: https://cli.github.com/" >&2
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI" >&2
    echo "Please run: gh auth login" >&2
    exit 1
fi

echo "# Import blocks for GitHub organization users: $ORG_NAME"
echo "# Generated on $(date)"
echo ""

# Import members
echo "# GitHub organization members"
gh api "orgs/$ORG_NAME/members" --jq '.[] | .login' | while read -r username; do
    echo "import {"
    echo "  to = github_membership.members[\"$username\"]"
    echo "  id = \"$ORG_NAME:$username\""
    echo "}"
    echo ""
done
