#!/bin/bash

# Generate teams-import.tf with import blocks for GitHub teams
# Usage: ./generate-teams-import-tf.sh

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

echo "# Import blocks for GitHub organization teams: $ORG_NAME"
echo "# Generated on $(date)"
echo ""

# Import teams
TEAMS=$(gh api "orgs/$ORG_NAME/teams" --jq '.[] | @base64')

if [ -n "$TEAMS" ]; then
    echo "# GitHub teams"
    for team_data in $TEAMS; do
        team_json=$(echo "$team_data" | base64 --decode)
        team_name=$(echo "$team_json" | jq -r '.name')
        team_slug=$(echo "$team_json" | jq -r '.slug')
        team_id=$(echo "$team_json" | jq -r '.id')

        echo "import {"
        echo "  to = github_team.teams[\"$team_name\"]"
        echo "  id = \"$team_id\""
        echo "}"
        echo ""

        # Import team maintainers
        MAINTAINERS=$(gh api "orgs/$ORG_NAME/teams/$team_slug/members?role=maintainer" --jq '.[] | .login' 2>/dev/null || echo "")
        if [ -n "$MAINTAINERS" ]; then
            echo "$MAINTAINERS" | while read -r maintainer; do
                echo "import {"
                echo "  to = github_team_membership.team_maintainers[\"$team_name-$maintainer\"]"
                echo "  id = \"$team_id:$maintainer\""
                echo "}"
                echo ""
            done
        fi

        # Import team members
        MEMBERS=$(gh api "orgs/$ORG_NAME/teams/$team_slug/members?role=member" --jq '.[] | .login' 2>/dev/null || echo "")
        if [ -n "$MEMBERS" ]; then
            echo "$MEMBERS" | while read -r member; do
                echo "import {"
                echo "  to = github_team_membership.team_members[\"$team_name-$member\"]"
                echo "  id = \"$team_id:$member\""
                echo "}"
                echo ""
            done
        fi
    done
else
    echo "# No teams found in organization"
fi
