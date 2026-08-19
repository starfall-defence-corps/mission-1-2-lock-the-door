#!/usr/bin/env bash
# ARIA submission pipeline — branch, commit your workspace, push, open a PR.
# Manual git remains the advanced path; this is the one-command version.
set -u

MISSION="Mission 1.2: Lock the Door"
BRANCH="mission-submission"

GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

say()  { echo -e "    ${GREEN}✓${RESET} $1"; }
note() { echo -e "    ${YELLOW}○${RESET} $1"; }
die()  {
    echo -e "    ${RED}✗${RESET} $1"
    echo -e "      ${DIM}↳ $2${RESET}"
    echo ""
    echo -e "  ${RED}${BOLD}ARIA: Submission aborted. Fix the item above and run 'make submit' again.${RESET}"
    echo ""
    exit 1
}

echo ""
echo -e "  ${CYAN}${BOLD}=============================================="
echo -e "  ARIA — Submission Pipeline"
echo -e "  ${MISSION}"
echo -e "  ==============================================${RESET}"
echo ""

# -- Preconditions -----------------------------------------------------------
git rev-parse --is-inside-work-tree > /dev/null 2>&1 \
    || die "Inside a git repository" "Run this from your mission repo checkout"

git remote get-url origin > /dev/null 2>&1 \
    || die "Git remote 'origin' configured" "Clone your own copy of the mission repo (created via 'Use this template') rather than downloading a zip"

if ! command -v gh > /dev/null 2>&1; then
    die "GitHub CLI (gh) installed" "Install it from https://cli.github.com — or submit manually: git checkout -b $BRANCH && git add workspace/ && git commit -m 'mission submission' && git push -u origin $BRANCH, then open a PR on GitHub"
fi
if ! gh auth status > /dev/null 2>&1; then
    die "GitHub CLI authenticated" "Run 'gh auth login' first (choose GitHub.com, HTTPS)"
fi
say "git + GitHub CLI ready"

# -- Branch ------------------------------------------------------------------
CURRENT=$(git branch --show-current)
if [ "$CURRENT" = "main" ] || [ "$CURRENT" = "master" ]; then
    if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        git checkout -q "$BRANCH" || die "Switch to branch $BRANCH" "Resolve the git error above and retry"
    else
        git checkout -q -b "$BRANCH" || die "Create branch $BRANCH" "Resolve the git error above and retry"
    fi
    say "On branch $BRANCH"
else
    BRANCH="$CURRENT"
    say "On branch $BRANCH (using your current branch)"
fi

# -- Commit ------------------------------------------------------------------
git add workspace/ 2>/dev/null
[ -f CHECKLIST.md ] && git add CHECKLIST.md 2>/dev/null

if git diff --cached --quiet; then
    note "No new changes to commit — submitting what's already committed"
else
    git commit -q -m "mission: progress submission" \
        || die "Commit your work" "git commit failed — check 'git status' and resolve, then retry"
    say "Work committed"
fi

# -- Push --------------------------------------------------------------------
git push -q -u origin "$BRANCH" \
    || die "Push to origin/$BRANCH" "Check your network and that you have push access to your own repo, then retry"
say "Pushed to origin/$BRANCH"

# -- Pull request ------------------------------------------------------------
EXISTING=$(gh pr list --head "$BRANCH" --state open --json url --jq '.[0].url' 2>/dev/null)
if [ -n "${EXISTING:-}" ]; then
    PR_URL="$EXISTING"
    say "Existing PR updated"
else
    PR_URL=$(gh pr create --base main --head "$BRANCH" \
        --title "Mission submission: ${MISSION}" \
        --body "Cadet submission for ARIA review. Run \`make test\` locally before requesting review." 2>/dev/null) \
        || die "Open the pull request" "Run 'gh pr create --base main --head $BRANCH' to see the underlying error"
    say "Pull request opened"
fi

echo ""
echo -e "  ${GREEN}${BOLD}ARIA: Submission logged. Review will appear on your PR."
echo -e "  ${PR_URL}${RESET}"
echo ""
