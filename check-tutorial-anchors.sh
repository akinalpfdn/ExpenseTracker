#!/bin/bash
# Every tour step must point at something.
#
# The tour broke three times because a step's copy described one control while its
# highlight sat on another — and nothing failed, because a step with no anchor still
# shows its tooltip. This is the check that catches it.
#
# Chapter three is exempt: all of its steps describe things inside the Settings sheet,
# which the tour cannot open, so the gear stays lit for the whole chapter instead.

set -e
cd "$(dirname "$0")"

MODEL=ExpenseTracker/Models/TutorialStep.swift
CHAPTER_THREE="settings|categories|limits|backup|reminder"
missing=0

ids=$(sed -n '/enum TutorialStepId/,/^}/p' "$MODEL" \
      | grep -oE '^\s+case [a-zA-Z]+' | sed 's/.*case //')

for id in $ids; do
    if echo "$id" | grep -qE "^($CHAPTER_THREE)$"; then
        continue
    fi
    if ! grep -rq "currentStepId == \.$id\b" ExpenseTracker --include="*.swift"; then
        echo "  no anchor: $id"
        missing=$((missing + 1))
    fi
done

if [ "$missing" -gt 0 ]; then
    echo "$missing step(s) describe something nothing highlights."
    exit 1
fi

echo "All tour steps are anchored."
