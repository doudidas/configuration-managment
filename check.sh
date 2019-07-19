#!/bin/bash
git diff $platform-current..remotes/origin/$platform-reference -- export/$1 | grep -e "^\+  .*" -e "^\-  .*" -e "\"Id.*" > /tmp/diff
if [[ -n $(cat /tmp/diff) ]]; then
    cat /tmp/diff
    exit 1
else
    exit 0
fi