#!/usr/bin/env bash
set -euo pipefail

SUBSCRIPTION_ID="${1:-}"
CSV_PATH="${2:-}"

if ! az account show >/dev/null 2>&1; then
  echo "Please 'az login' first." >&2
  exit 1
fi

if [[ -n "$SUBSCRIPTION_ID" ]]; then
  az account set --subscription "$SUBSCRIPTION_ID" >/dev/null
fi

QUERY=$'resources | where type =~ "microsoft.hybridcompute/machines" | project name, resourceGroup, subscriptionId, location, id'

JSON=$(az graph query -q "$QUERY" --first 1000)
echo "$JSON" | jq -r '.data[] | [.name, .resourceGroup, .subscriptionId, .location, .id] | @tsv' | \
  awk 'BEGIN{print "NAME\tRESOURCEGROUP\tSUBSCRIPTION\tLOCATION\tID"}{print $0}'

if [[ -n "$CSV_PATH" ]]; then
  echo "$JSON" | jq -r '
    (["name","resourceGroup","subscriptionId","location","id"] | @csv),
    (.data[] | [ .name, .resourceGroup, .subscriptionId, .location, .id ] | @csv)
  ' > "$CSV_PATH"
  echo "Saved CSV to $CSV_PATH"
fi
