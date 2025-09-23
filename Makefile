# Makefile for Azure Arc Decommissioning helpers
# Usage examples:
#   make help
#   make inventory SUB=<subscription-id> CSV=arc-machines.csv
#   make list-ext MACHINE=my-arc RG=rg-arc
#   make remove-common-ext MACHINE=my-arc RG=rg-arc
#   make disconnect MACHINE=my-arc RG=rg-arc
#   make disconnect-csv CSV=arc-machines.csv
#   make policy-dryrun SCOPE=/subscriptions/<subId>
#   make policy-delete SCOPE=/subscriptions/<subId>

SHELL := /usr/bin/env bash
REGEX ?= (?i)(\bArc\b|ArcBox|Change\s*Tracking|AzureMonitorWindowsAgent|AMA\b|MDE\.Windows)

# Detect whether PowerShell is available (pwsh preferred, otherwise powershell).
# If both Bash and PowerShell exist, Bash scripts are used by default for portability.
HAS_PWSH := $(shell command -v pwsh >/dev/null 2>&1 && echo yes || echo no)
HAS_POWERSHELL := $(shell command -v powershell >/dev/null 2>&1 && echo yes || echo no)

# --- General ---
.PHONY: help
help:
	@echo "Azure Arc Decommissioning helper targets"
	@echo
	@echo "Inventory:"
	@echo "  make inventory SUB=<subscription-id> [CSV=arc-machines.csv]"
	@echo
	@echo "Extensions:"
	@echo "  make list-ext MACHINE=<name> RG=<resource-group>"
	@echo "  make remove-ext MACHINE=<name> RG=<resource-group> EXT=<extension-name>"
	@echo "  make remove-common-ext MACHINE=<name> RG=<resource-group>"
	@echo
	@echo "Disconnect:"
	@echo "  make disconnect MACHINE=<name> RG=<resource-group>"
	@echo "  make disconnect-csv CSV=<path-to-csv>"
	@echo
	@echo "Policy hygiene:"
	@echo "  make policy-dryrun SCOPE=<scope> [REGEX='$(REGEX)']"
	@echo "  make policy-delete SCOPE=<scope> [REGEX='$(REGEX)']"
	@echo

# --- Inventory ---
.PHONY: inventory
inventory:
	@if [ -n "$(SUB)" ]; then \
	  ./scripts/list-arc-machines.sh "$(SUB)" "$(CSV)"; \
	else \
	  ./scripts/list-arc-machines.sh "" "$(CSV)"; \
	fi

# --- Extensions ---
.PHONY: list-ext
list-ext:
	@test -n "$(MACHINE)" || (echo "Set MACHINE=<name>"; exit 1)
	@test -n "$(RG)" || (echo "Set RG=<resource-group>"; exit 1)
	./scripts/list-arc-extensions.sh "$(MACHINE)" "$(RG)"

.PHONY: remove-ext
remove-ext:
	@test -n "$(MACHINE)" || (echo "Set MACHINE=<name>"; exit 1)
	@test -n "$(RG)" || (echo "Set RG=<resource-group>"; exit 1)
	@test -n "$(EXT)" || (echo "Set EXT=<extension-name>"; exit 1)
	./scripts/remove-arc-extension.sh -m "$(MACHINE)" -g "$(RG)" -e "$(EXT)"

.PHONY: remove-common-ext
remove-common-ext:
	@test -n "$(MACHINE)" || (echo "Set MACHINE=<name>"; exit 1)
	@test -n "$(RG)" || (echo "Set RG=<resource-group>"; exit 1)
	./scripts/remove-arc-extension.sh -m "$(MACHINE)" -g "$(RG)" --common-set

# --- Disconnect ---
.PHONY: disconnect
disconnect:
	@test -n "$(MACHINE)" || (echo "Set MACHINE=<name>"; exit 1)
	@test -n "$(RG)" || (echo "Set RG=<resource-group>"; exit 1)
	./scripts/disconnect-arc.sh -m "$(MACHINE)" -g "$(RG)"

.PHONY: disconnect-csv
disconnect-csv:
	@test -n "$(CSV)" || (echo "Set CSV=<path-to-csv>"; exit 1)
	./scripts/disconnect-arc.sh --csv "$(CSV)"

# --- Policy Hygiene ---
.PHONY: policy-dryrun
policy-dryrun:
	@test -n "$(SCOPE)" || (echo "Set SCOPE=<scope>"; exit 1)
	./scripts/policy-hygiene.sh "$(SCOPE)" '$(REGEX)'

.PHONY: policy-delete
policy-delete:
	@test -n "$(SCOPE)" || (echo "Set SCOPE=<scope>"; exit 1)
	./scripts/policy-hygiene.sh "$(SCOPE)" '$(REGEX)' true

.PHONY: sanitize-check sanitize
sanitize-check:
	@! grep -IUPrn --color=always '\x07' -- . \
	  || (echo "Found ASCII bell(s) ↑ — run 'make sanitize'."; exit 1)

sanitize:
	@python - <<'PY'
import os
for root,_,files in os.walk('.'):
    for fn in files:
        if fn.endswith(('.md','.txt','.ps1','.sh','.yaml','.yml','.json')):
            p=os.path.join(root,fn)
            with open(p,'rb') as f: b=f.read()
            if b'\x07' in b:
                with open(p,'wb') as f: f.write(b.replace(b'\x07',b'\\'))
                print("fixed", p)
print("sanitize complete")
PY
