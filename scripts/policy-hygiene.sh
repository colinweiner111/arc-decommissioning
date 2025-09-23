#!/usr/bin/env bash
set -euo pipefail

SCOPE="${1:-}"
REGEX="${2:-(?i)(\\bArc\\b|ArcBox|Change[[:space:]]*Tracking|AzureMonitorWindowsAgent|AMA\\b|MDE\\.Windows)}"
DELETE="${3:-false}"

args=( policy assignment list --disable-scope-strict-match )
if [[ -n "$SCOPE" ]]; then
  args+=( --scope "$SCOPE" )
fi

JSON=$(az "${args[@]}")
echo "Matching policy assignments (regex: $REGEX)"
echo "$JSON" | jq -r --arg re "$REGEX" '
  .[] | select(.displayName|test($re)) | [.name, .displayName, .scope] | @tsv
' | awk 'BEGIN{print "NAME\tDISPLAYNAME\tSCOPE"}{print $0}'

if [[ "$DELETE" == "true" ]]; then
  echo
  echo "Deleting matched assignments..."
  echo "$JSON" | jq -r --arg re "$REGEX" '.[] | select(.displayName|test($re)) | [.name, .scope] | @tsv' | \
  while IFS=$'\t' read -r name scope; do
    if az policy assignment delete --name "$name" --scope "$scope"; then
      echo "Deleted $name at $scope"
    else
      echo "WARN: Failed to delete $name at $scope" >&2
    fi
  done
else
  echo
  echo "Dry run. To delete, pass third argument 'true' (e.g., ./policy-hygiene.sh <scope> '<regex>' true)"
fi
