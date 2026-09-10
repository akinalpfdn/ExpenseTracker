#!/bin/bash
# Every tour step must have a view registered as its target.
#
# A step whose target nobody registered still shows its callout — centred, with
# nothing spotlit — so nothing fails on its own. This does.

set -e
cd "$(dirname "$0")"

MODEL=ExpenseTracker/Models/TourStep.swift
missing=0

ids=$(sed -n '/enum TourStepID/,/^}/p' "$MODEL" | grep -oE '^\s+case [a-zA-Z]+' | sed 's/.*case //')

for id in $ids; do
    if ! grep -rqE "\.tourTarget\(\.$id\b" ExpenseTracker --include="*.swift"; then
        echo "  no target registered for: $id"
        missing=$((missing + 1))
    fi
done

if [ "$missing" -gt 0 ]; then
    echo "$missing step(s) point at nothing."
    exit 1
fi

echo "Every tour step has a target."
