#!/bin/bash
currentBranch=$2-current
referenceBranch=remotes/origin/$2-reference

git diff $referenceBranch..$currentBranch -- export/$1/* | grep -e "^\+  .*" -e "^\-  .*" -e "^\+++.*" -e "^\---.*"> /tmp/$1
if [[ -n $(cat /tmp/$1) ]]; then
    cat /tmp/diff
    exit 1
else
    exit 0
fi