#!/bin/bash
currentBranch=$(git rev-parse --abbrev-ref HEAD)
remoteBranch=${currentBranch/current/reference}
echo $remoteBranch
git diff $currentBranch..$remoteBranch -- export/$1/* | grep -e "^\+  .*" -e "^\-  .*" -e "^\+++.*" -e "^\---.*"> /tmp/diff
if [[ -n $(cat /tmp/diff) ]]; then
    cat /tmp/diff
    exit 1
else
    exit 0
fi