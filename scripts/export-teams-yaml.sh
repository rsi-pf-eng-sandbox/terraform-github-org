#!/bin/bash

# GitHub Organization Teams Data Import Script
# Usage: ./scripts/import-teams-from-github.sh

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

# Generate teams.yaml to stdout
echo "teams:"

# Fetch teams
TEAMS=$(gh api "orgs/$ORG_NAME/teams" --jq '.[] | @base64')

if [ -z "$TEAMS" ]; then
    echo "  # No teams found or no access to teams"
else
    for team_data in $TEAMS; do
        team_json=$(echo "$team_data" | base64 --decode)
        team_name=$(echo "$team_json" | jq -r '.name')
        team_slug=$(echo "$team_json" | jq -r '.slug')
        team_desc=$(echo "$team_json" | jq -r '.description // ""')
        team_privacy=$(echo "$team_json" | jq -r '.privacy')

        echo "  - name: \"$team_name\""
        echo "    description: \"$team_desc\""
        echo "    privacy: \"$team_privacy\""

        # Fetch team members
        echo "    maintainers:"
        MAINTAINERS=$(gh api "orgs/$ORG_NAME/teams/$team_slug/members?role=maintainer" --jq '.[] | .login' 2>/dev/null || echo "")
        if [ -z "$MAINTAINERS" ]; then
            echo "      []"
        else
            echo "$MAINTAINERS" | while read -r maintainer; do
                echo "      - \"$maintainer\""
            done
        fi

        echo "    members:"
        MEMBERS=$(gh api "orgs/$ORG_NAME/teams/$team_slug/members?role=member" --jq '.[] | .login' 2>/dev/null || echo "")
        if [ -z "$MEMBERS" ]; then
            echo "      []"
        else
            echo "$MEMBERS" | while read -r member; do
                echo "      - \"$member\""
            done
        fi

        echo ""
    done
fi
