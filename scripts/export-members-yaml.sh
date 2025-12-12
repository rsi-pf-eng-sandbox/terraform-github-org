#!/bin/bash

# GitHub Organization Users Data Import Script
# Usage: ./scripts/import-users-from-github.sh

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

# Generate members.yaml to stdout
echo "members:"

# Fetch members with their roles and output to stdout
gh api "orgs/$ORG_NAME/members" --jq '.[] | @base64' | while read -r member_data; do
    member_json=$(echo "$member_data" | base64 --decode)
    username=$(echo "$member_json" | jq -r '.login')

    # Get the member's role by checking membership details
    role=$(gh api "orgs/$ORG_NAME/memberships/$username" --jq '.role' 2>/dev/null || echo "member")

    echo "  - username: \"$username\""
    echo "    email: \"\""
    echo "    role: \"$role\""
done
