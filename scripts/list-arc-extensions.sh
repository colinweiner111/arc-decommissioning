#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <machine-name> <resource-group>" >&2
  exit 1
fi

MACHINE_NAME="$1"
RESOURCE_GROUP="$2"

az connectedmachine extension list --machine-name "$MACHINE_NAME" --resource-group "$RESOURCE_GROUP" --output table
