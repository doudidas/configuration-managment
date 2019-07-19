#!/bin/bash
currentBranch=$(git rev-parse --abbrev-ref HEAD)
echo $currentBranch
git diff $currentBranch..remotes/origin/$2-reference -- export/$1/*
git diff $currentBranch..remotes/origin/$2-reference -- export/$1/* | grep -e "^\+  .*" -e "^\-  .*" -e "\"Id.*" > /tmp/diff
if [[ -n $(cat /tmp/diff) ]]; then
    cat /tmp/diff
    exit 1
else
    exit 0
fi