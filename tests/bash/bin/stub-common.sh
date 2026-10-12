#!/bin/bash
# Shared helper sourced by the docker/compose stub scripts.
# Records non-flag args to a state file for test assertions.

# stub_record_args <file> <args...>
# Appends each non-flag arg on its own line to <file>.
stub_record_args() {
    local file="$1"
    shift
    local a
    for a in "$@"; do
        [[ "$a" == -* ]] && continue
        echo "$a" >> "$file"
    done
}