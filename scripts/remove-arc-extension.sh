#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage:
  $0 -m <machine-name> -g <resource-group> [-e <extension-name>] [--common-set]

Removes an Azure Arc extension from a machine.
--common-set removes: MDE.Windows, AzureMonitorWindowsAgent, ChangeTracking
EOF
  exit 1
}

MACHINE_NAME=""; RESOURCE_GROUP=""; EXT_NAME=""; COMMON=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m) MACHINE_NAME="$2"; shift 2;;
    -g) RESOURCE_GROUP="$2"; shift 2;;
    -e) EXT_NAME="$2"; shift 2;;
    --common-set) COMMON=true; shift;;
    *) usage;;
  esac
done

[[ -z "$MACHINE_NAME" || -z "$RESOURCE_GROUP" ]] && usage
if ! $COMMON && [[ -z "$EXT_NAME" ]]; then usage; fi

TARGETS=()
if $COMMON; then
  TARGETS=("MDE.Windows" "AzureMonitorWindowsAgent" "ChangeTracking")
else
  TARGETS=("$EXT_NAME")
fi

for ext in "${TARGETS[@]}"; do
  if az connectedmachine extension delete --name "$ext" --machine-name "$MACHINE_NAME" --resource-group "$RESOURCE_GROUP" --yes; then
    echo "Removed extension '$ext' on '$MACHINE_NAME'."
  else
    echo "WARN: Failed to remove extension '$ext' on '$MACHINE_NAME'." >&2
  fi
done
