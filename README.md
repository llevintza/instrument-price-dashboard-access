# instrument-price-dashboard-access

Requests for access to the private [instrument-price-dashboard](https://github.com/llevintza/instrument-price-dashboard) repo. The source of this repo is kept in that repo under `tools/access-intake/` (#147), and the design is its ADR 0023 (intake A, amended 2026-10-31).

## Ask for access

1. Sign in to GitHub as the account that should get access.
2. Open **[Request repo access](https://github.com/llevintza/instrument-price-dashboard-access/issues/new?template=access-request.yml)**, tick the two boxes, add a note if you like, and submit.
3. The owner reviews it. If it's approved, GitHub emails you an invitation; accept it from the email or from the repo's invitations page. The issue is commented on and closed either way.

Nobody types a username: the account that opens the issue is the one that's invited.

**What's public here:** your GitHub login, avatar and profile link as the issue author, your note, the dates, every label the request passes through (including `status:declined`), and the comments, which name the private repo and link to its invitations page. That link works only for the invitee. No email address, app account or token ever appears here. If you'd rather leave no trace, ask the owner directly.

**What access you get:** read access once the repo is in the `llevintza-labs` organization. Until then it belongs to a personal account, where GitHub gives every collaborator push access; `main` still accepts changes only through reviewed PRs, and the owner removes access when your review is over.

## How a request moves

| Label | Set by | Next |
|---|---|---|
| `access-request`, `status:pending` | the form | `status:approved` or `status:declined` |
| `status:approved` | the owner only | the `grant` job, after the owner approves its run in the `repo-access` environment |
| `status:granted` | the `grant` job, which comments and closes the issue | final |
| `status:declined` | the owner; the `decline` job comments and closes the issue, with no token | final |

The workflow is [`.github/workflows/access-request.yml`](.github/workflows/access-request.yml). Both jobs skip unless the label was added by the approver to an open `access-request` issue. `grant` reads the requester's login from the event, never from the issue text, and calls `PUT /repos/{TARGET_REPO}/collaborators/{author}` with `permission=pull`. A failed grant comments, leaves the issue open with `status:approved`, and can be re-run; re-running for someone who is already a collaborator changes nothing.

## Owner setup

Everything except the token is scripted, and the script never touches a secret:

```bash
GH_TOKEN="$(gh auth token --user llevintza)" ./setup.sh
```

It creates the five labels, sets the `TARGET_REPO` and `APPROVER_LOGIN` variables, creates the `repo-access` environment with the approver as its required reviewer and `main` as its only deployment branch, makes the default `GITHUB_TOKEN` read-only, allows no actions (the workflow only runs `gh`), and turns off the wiki, projects and discussions.

Then, by hand:

0. **First, while `TARGET_REPO` is still a personal-account repo, meet ADR 0023 decision 11's preconditions there.** Move every repository-level deploy secret into the `main`-only `production` environment (#164) and contain the open PR branches. Don't create or store the token until both are done: without it the grant step fails and nothing is granted.
1. **Create the token.** GitHub → Settings → Developer settings → Fine-grained tokens → Generate. Resource owner: the owner of `TARGET_REPO`. Repository access: only `TARGET_REPO`. Permissions: **Administration: read and write** (Metadata: read comes with it), nothing else. Set an expiry and rotate it.
2. **Store it** as the environment secret, from a prompt so it stays out of shell history: `gh secret set REPO_ACCESS_TOKEN --env repo-access -R llevintza/instrument-price-dashboard-access`. Never as a repository secret.
3. **Check the environment** (Settings → Environments → `repo-access`): you are the required reviewer and only `main` can deploy. The script sets both; add yourself by hand if the API refused.

## Dry run

1. From a test GitHub account, open the form and submit. The issue gets `access-request` and `status:pending`.
2. As the owner, add `status:approved`. The `grant` run waits for review; approve it under Actions.
3. Check: the test account gets GitHub's invitation email; the issue has a comment, `status:granted`, and is closed; the run log shows no token. The collaborator call must succeed (201) on the personal-account repo too; if GitHub rejects `permission=pull` there (422), drop the parameter until `TARGET_REPO` is an org repo.
4. Revoke: `gh api -X DELETE repos/$TARGET_REPO/collaborators/<login>` (or cancel a pending invitation in the repo's Settings → Collaborators).
5. Open a second request and add `status:declined`: it's commented on and closed, and no environment approval is asked for.

## Moving to the organization

When `instrument-price-dashboard` moves to `llevintza-labs`, set `TARGET_REPO` to `llevintza-labs/instrument-price-dashboard` (re-run `setup.sh` with that value). Then create a **new** fine-grained token whose resource owner is the org (a token's resource owner can't be changed, and the org must allow fine-grained tokens), store it as `REPO_ACCESS_TOKEN` as above, and delete the old token. Nothing else changes. The workflow passes `permission=pull` explicitly because an org repo would otherwise default to push; on the personal repo GitHub ignores it, and in the org it grants read only.
