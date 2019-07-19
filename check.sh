#!/bin/bash
currentBranch=$2-current
referenceBranch=remotes/origin/$2-reference

git diff $referenceBranch..$currentBranch -- export/$1/* | grep -e "^\+  .*" -e "^\-  .*" -e "^\+++.*" -e "^\---.*"> diff/$1.txt
if [[ -n $(cat diff/$1.txt) ]]; then
    cat diff/$1.txt
    exit 1
else
    exit 0
fi