#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage:
  $0 -m <machine-name> -g <resource-group>
  $0 --csv <path>

CSV must have headers: name,resourceGroup
EOF
  exit 1
}

MACHINE_NAME=""; RESOURCE_GROUP=""; CSV_PATH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m) MACHINE_NAME="$2"; shift 2;;
    -g) RESOURCE_GROUP="$2"; shift 2;;
    --csv) CSV_PATH="$2"; shift 2;;
    *) usage;;
  esac
done

items() {
  if [[ -n "$CSV_PATH" ]]; then
    # Skip header; expect comma-separated columns: name,resourceGroup
    tail -n +2 "$CSV_PATH" | while IFS=, read -r name rg rest; do
      [[ -n "$name" && -n "$rg" ]] && echo "$rg,$name"
    done
  else
    [[ -z "$MACHINE_NAME" || -z "$RESOURCE_GROUP" ]] && usage
    echo "$RESOURCE_GROUP,$MACHINE_NAME"
  fi
}

while IFS=, read -r rg name; do
  if az connectedmachine delete --name "$name" --resource-group "$rg" --yes; then
    echo "Deleted Arc resource $name in $rg."
  else
    echo "WARN: Failed to delete Arc resource $name in $rg." >&2
  fi
done < <(items)

echo
echo "Note: For a CLEAN disconnect, run ON THE SERVER:"
echo "  azcmagent disconnect"
