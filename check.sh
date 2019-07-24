#!/bin/bash

referenceBranch=remotes/origin/$2-reference

git diff -v $referenceBranch -- export/$1/* | grep -e "^\+  .*" -e "^\-  .*" -e "^\+++.*" -e "^\---.*" > diff/$1.log
if [[ -n $(cat diff/$1.log) ]]; then
    cat diff/$1.txt
    exit 1
else
    exit 0
fi