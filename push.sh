#!/bin/bash
git push 
git push -f origin dev:lab-current
git push -f origin dev:lab-reference
git push -f origin dev:maquette-current
git push -f origin dev:maquette-reference
git push -f origin dev:production-current
git push -f origin dev:production-reference