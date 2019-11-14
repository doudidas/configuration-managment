#!/bin/bash
git push 
git push -f origin master:lab-current
git push -f origin master:lab-reference
git push -f origin master:maquette-current
git push -f origin master:maquette-reference
git push -f origin master:production-current
git push -f origin master:production-reference