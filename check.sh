#!/bin/bash
currentBranch=$2-current
referenceBranch=remotes/origin/$2-reference

git diff $referenceBranch..$currentBranch -- export/$1/* | grep -e "^\+  .*" -e "^\-  .*" -e "^\+++.*" -e "^\---.*"> /tmp/diff
if [[ -n $(cat /tmp/diff) ]]; then
    cat /tmp/diff
    exit 1
else
    exit 0
fi