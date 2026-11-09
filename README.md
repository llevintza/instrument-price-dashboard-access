# instrument-price-dashboard-access

Requests for access to the private [instrument-price-dashboard](https://github.com/llevintza/instrument-price-dashboard) repo.

## Ask for access

1. Sign in to GitHub as the account that should get access.
2. Open **[Request repo access](https://github.com/llevintza/instrument-price-dashboard-access/issues/new?template=access-request.yml)**, tick the two boxes, add a note if you like, and submit.
3. The owner reviews it. If it's approved, GitHub emails you an invitation; accept it from the email or from the repo's invitations page. The issue is commented on and closed either way.

Nobody types a username: the account that opens the issue is the one that's invited.

The dashboard's **View on GitHub** button does this for you: it asks GitHub, through the read-only "IPD repo access" app, whether your account can already open the repo, and sends you either to the repo or to this form.

## What's public here

Your GitHub login, avatar and profile link as the issue author, your note, the dates, every label the request passes through (including `status:declined`), and the comments, which name the private repo and link to its invitations page. That link works only for the invitee. No email address, app account or token ever appears here. If you'd rather leave no trace, ask the owner directly.

## What you get

Collaborator access to the repo for your review. While the repo belongs to a personal account, GitHub gives every collaborator push access; `main` still accepts changes only through reviewed pull requests. Once it moves to an organization, access is read-only. The owner removes it when the review is over.

## How a request moves

| Label | Meaning |
|---|---|
| `access-request`, `status:pending` | Submitted, waiting for the owner |
| `status:approved` | Approved; the invitation is on its way (the owner may skip this and go straight to `status:granted`) |
| `status:granted` | Invitation sent; the issue is closed |
| `status:declined` | Declined; the issue is closed |

The workflow that handles the labels is [`.github/workflows/access-request.yml`](.github/workflows/access-request.yml). Only the owner can approve a request, and the account invited is always the issue's author.
