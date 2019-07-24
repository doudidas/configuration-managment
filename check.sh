#!/bin/bash

referenceBranch=remotes/origin/$2-reference

git diff -v $referenceBranch -- export/$1/* | grep -e "^\+  .*" -e "^\-  .*" -e "^\+++.*" -e "^\---.*" > diff/$1.log
tmp=$(cat diff/$1.log | grep -e "^\---.*")
if [[ -n $(cat diff/$1.log) ]]; then
    echo $tmp
    echo $tmp > tmp.txt
    exit 1
else
    exit 0
fi