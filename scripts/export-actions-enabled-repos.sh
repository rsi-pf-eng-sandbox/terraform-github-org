#!/bin/bash

# Export enabled repositories for GitHub Actions to YAML format
# Usage: ./export-actions-enabled-repos.sh > data/actions-enabled-repositories.yaml

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

echo "repositories:"

# Get enabled repositories directly from the repositories endpoint
ENABLED_REPOS=$(gh api "orgs/$ORG_NAME/actions/permissions/repositories" --jq '.repositories[]?.name // empty')

if [ -z "$ENABLED_REPOS" ]; then
    echo "  # No repositories currently enabled for Actions"
else
    # Output repository names in YAML format
    for repo_name in $ENABLED_REPOS; do
        echo "  - \"$repo_name\""
    done
fi
