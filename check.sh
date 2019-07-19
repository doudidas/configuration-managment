#!/bin/bash
currentBranch=$platform-current
referenceBranch=remotes/origin/$platform-reference

git diff $currentBranch..$referenceBranch -- export/$1/* | grep -e "^\+  .*" -e "^\-  .*" -e "^\+++.*" -e "^\---.*"> /tmp/diff
if [[ -n $(cat /tmp/diff) ]]; then
    cat /tmp/diff
    exit 1
else
    exit 0
fi