# Secure Daily GitHub Contribution Automation

This repository contains a small GitHub Actions workflow that appends one useful maintenance entry to `daily-activity.md`, commits it, and pushes it to the repository once per Pakistan calendar day. It uses the Actions-provided `GITHUB_TOKEN`; no password or personal access token is stored in the repository.

## How It Works

The workflow in `.github/workflows/daily-contribution.yml`:

1. Starts at 04:00 UTC every day, or through `workflow_dispatch`.
2. Checks that the required repository variables exist.
3. Runs `scripts/daily_update.py`, which uses `Asia/Karachi` and refuses to add a second `## YYYY-MM-DD` entry.
4. Configures Git from repository variables, commits the changed file, and pushes with the automatically supplied Actions token.
5. Sends an optional success or failure notification.

Scheduled workflows can start late because GitHub queues scheduled jobs under platform load. The cron expression is still the correct target time, but it is not a hard real-time guarantee.

## Install

1. Put this directory in a GitHub repository. The commit must be on the repository's default branch for the normal contribution graph rules to apply.
2. In **Settings > Actions > General**, allow actions and ensure the workflow can write repository contents. If the repository is in an organization, an organization policy may also need to allow this.
3. In **Settings > Actions > General > Workflow permissions**, select **Read and write permissions**, or use an organization policy that permits the workflow's explicit `contents: write` permission.
4. Add the repository variables and optional secrets described below.
5. Commit and push the workflow to the default branch.
6. Open **Actions > Daily repository maintenance > Run workflow** to test it manually.

## Required Repository Variables

Set these in **Settings > Secrets and variables > Actions > Variables**:

| Name | Value |
| --- | --- |
| `COMMIT_AUTHOR_NAME` | Your GitHub account name, used as the commit author name. |
| `COMMIT_AUTHOR_EMAIL` | An email verified on your GitHub account, or your GitHub-provided noreply email. Do not invent one. |
| `NOTIFICATION_PROVIDER` | `none`, `discord`, or `telegram`. Use `none` to disable external notifications. |

The workflow's `GITHUB_TOKEN` is short-lived and supplied by GitHub Actions. It is not necessary to create or store a personal access token for this repository.

For the commit to be associated with your account, the configured email must be verified on that account or be the account's GitHub noreply address. The author name alone is not enough.

## Notifications

Notifications are optional and disabled with `NOTIFICATION_PROVIDER=none`. The message never includes tokens or webhook URLs.

### Discord

1. Create a Discord webhook for the target channel.
2. Add an Actions repository secret named `DISCORD_WEBHOOK_URL` containing that URL.
3. Set `NOTIFICATION_PROVIDER` to `discord`.

### Telegram

1. Create a bot with BotFather and obtain its token.
2. Determine the destination chat ID.
3. Add Actions secrets named `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`.
4. Set `NOTIFICATION_PROVIDER` to `telegram`.

Success notifications include the repository, Pakistan date, commit (or that no new commit was needed), and workflow status. Failure notifications include the repository, Pakistan date, failed step, and a link to the workflow run.

## Schedule

Pakistan Standard Time is UTC+5, so 09:00 in `Asia/Karachi` is 04:00 UTC. The workflow uses:

```yaml
- cron: '0 4 * * *'
```

Pakistan does not currently use daylight-saving changes, but the updater still uses the named `Asia/Karachi` time zone when choosing the calendar date and timestamp.

## Manual Runs and Duplicate Safety

Use **Actions > Daily repository maintenance > Run workflow**. A run that finds an existing `## YYYY-MM-DD` header exits successfully without changing, committing, or pushing anything. This also protects against retries and overlapping manual runs; the workflow additionally uses a concurrency group.

## Testing

Before enabling the schedule, inspect the workflow and run it manually:

```bash
python3 scripts/daily_update.py /tmp/test-daily-activity.md
python3 scripts/daily_update.py /tmp/test-daily-activity.md
```

The second command should report `updated=false`, and the file should contain only one dated header. For a repository-level test, run the workflow manually and confirm that the activity file changes once, the commit is pushed, and a second manual run reports no new commit. Test each configured notification provider with a manual run. Never use real credentials in local test files.

## Troubleshooting

- **Missing configuration:** Set both `GITHUB_USERNAME` and `GITHUB_COMMIT_EMAIL` as repository variables. The email must be verified by GitHub.
- **Push rejected:** Check that the workflow has repository `contents: write` permission and that organization policies allow it. The workflow must run on a branch it can push to.
- **No contribution shown:** GitHub contribution rules still apply. The commit must be pushed to the default branch (or an eligible pull request), use an email associated with your account, and belong to a repository where your account is eligible to receive contributions. A successful push alone does not guarantee a graph contribution.
- **Notification failure:** Confirm `NOTIFICATION_PROVIDER` exactly matches `none`, `discord`, or `telegram`, then check the relevant secret names and the workflow log. Secret values are masked and are not printed by the scripts.
- **Late run:** Scheduled Actions are best effort and may be delayed by GitHub load. Check the run history and the workflow link in the notification.

## Disable or Remove It

To pause automation without deleting files, disable the workflow from its Actions page. To remove it permanently, delete or rename `.github/workflows/daily-contribution.yml`. Set `NOTIFICATION_PROVIDER=none` to stop external notifications while retaining the daily update.

## Security Notes

- The only workflow permission is `contents: write`, which is required to commit and push.
- No password, personal access token, webhook URL, or bot token is hard-coded.
- Do not commit `.env` files or paste secrets into YAML, Python, or shell files.
- Review the activity entry before relying on this in a production repository, and keep the workflow's dependencies minimal.
