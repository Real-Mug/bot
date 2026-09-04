#!/usr/bin/env bash
set -Eeuo pipefail

result="${1:?notification result is required}"
repository="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
date_text="$(TZ=Asia/Karachi date +%F)"
provider="${NOTIFICATION_PROVIDER:-none}"
run_url="${RUN_URL:?RUN_URL is required}"

if [[ "$result" == "success" ]]; then
  message="Daily GitHub automation completed successfully. Repository: ${repository}. Date: ${date_text}. Commit: ${COMMIT}. Workflow status: successful."
else
  message="Daily GitHub automation failed. Repository: ${repository}. Date: ${date_text}. Failed step: ${FAILED_STEP}. Workflow: ${run_url}"
fi

case "$provider" in
  none)
    exit 0
    ;;
  discord)
    : "${DISCORD_WEBHOOK_URL:?DISCORD_WEBHOOK_URL secret is required}"
    curl --fail --silent --show-error --max-time 20 \
      -H 'Content-Type: application/json' \
      --data-raw "$(python3 -c 'import json,sys; print(json.dumps({"content": sys.argv[1]}))' "$message")" \
      "$DISCORD_WEBHOOK_URL" >/dev/null
    ;;
  telegram)
    : "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN secret is required}"
    : "${TELEGRAM_CHAT_ID:?TELEGRAM_CHAT_ID secret is required}"
    curl --fail --silent --show-error --max-time 20 \
      --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
      --data-urlencode "text=${message}" \
      "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" >/dev/null
    ;;
  *)
    echo "Unsupported notification provider: $provider" >&2
    exit 1
    ;;
esac
