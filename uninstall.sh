#!/usr/bin/env bash

set -e
set -x

# Remove consul-* from catalog
br catalog list application | awk '$1~/^consul-.*$/{print $1}' | xargs -n 1 br catalog delete application
br catalog list entity | awk '$1~/^consul-.*$/{print $1}' | xargs -n 1 br catalog delete entity
# Double check
br catalog list application | grep -E '^consul-' && { echo >&2 "there's still some stuff in the catalog (why?)"; exit 1; } || true
br catalog list entity | grep -E '^consul-' && { echo >&2 "there's still some stuff in the catalog (why?)"; exit 1; } || true
