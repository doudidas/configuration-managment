#!/bin/bash
git diff development-current..remotes/origin/development-reference -- export/$1 > /tmp/diff
if [[ -n $(cat /tmp/diff) ]]; then
    cat /tmp/diff
    exit 1
else
    exit 0
fi