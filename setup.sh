#!/usr/bin/env bash
# Configures the intake repo's labels, variables, environment and Actions settings (#147).
# Idempotent, and it never reads or writes a secret: the owner stores REPO_ACCESS_TOKEN by hand.
#
#   INTAKE_REPO=llevintza/instrument-price-dashboard-access \
#   TARGET_REPO=llevintza/instrument-price-dashboard \
#   APPROVER=llevintza ./setup.sh
#
# After the move to the llevintza-labs org, re-run it with only TARGET_REPO changed.
set -euo pipefail

INTAKE_REPO="${INTAKE_REPO:-llevintza/instrument-price-dashboard-access}"
TARGET_REPO="${TARGET_REPO:-llevintza/instrument-price-dashboard}"
APPROVER="${APPROVER:-llevintza}"

label() {
  gh label create "$1" --color "$2" --description "$3" --force -R "$INTAKE_REPO"
}

# The ADR 0023 decision 7 state machine, plus the form's own label.
label "access-request" "0e8a16" "A request for access to the private repo (set by the form)"
label "status:pending" "fbca04" "Waiting for the owner (set by the form)"
label "status:approved" "1d76db" "Approved by the owner; the grant job waits for its environment approval"
label "status:granted" "0e8a16" "Invitation sent by the grant job; final"
label "status:declined" "b60205" "Declined by the owner; final"

gh variable set TARGET_REPO --body "$TARGET_REPO" -R "$INTAKE_REPO"
gh variable set APPROVER_LOGIN --body "$APPROVER" -R "$INTAKE_REPO"

# repo-access: the approver must approve every grant run, and only the default branch may deploy.
approver_id="$(gh api "users/$APPROVER" --jq .id)"
gh api --silent -X PUT "repos/$INTAKE_REPO/environments/repo-access" --input - <<JSON
{
  "reviewers": [{ "type": "User", "id": $approver_id }],
  "prevent_self_review": false,
  "deployment_branch_policy": { "protected_branches": false, "custom_branch_policies": true }
}
JSON
if ! gh api "repos/$INTAKE_REPO/environments/repo-access/deployment-branch-policies" \
  --jq '.branch_policies[].name' | grep -qx main; then
  gh api --silent -X POST "repos/$INTAKE_REPO/environments/repo-access/deployment-branch-policies" \
    -f name=main -f type=branch
fi

# Read-only GITHUB_TOKEN by default (jobs ask for issues: write themselves), no PR approvals by
# Actions, and no actions at all: the workflow only runs gh, which the runner image ships.
gh api --silent -X PUT "repos/$INTAKE_REPO/actions/permissions/workflow" \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
gh api --silent -X PUT "repos/$INTAKE_REPO/actions/permissions" \
  -F enabled=true -f allowed_actions=selected
gh api --silent -X PUT "repos/$INTAKE_REPO/actions/permissions/selected-actions" \
  -F github_owned_allowed=false -F verified_allowed=false
gh repo edit "$INTAKE_REPO" --enable-wiki=false --enable-projects=false --enable-discussions=false

echo "Done. The owner still stores the token (never pass it as an argument):"
echo "  gh secret set REPO_ACCESS_TOKEN --env repo-access -R $INTAKE_REPO"
