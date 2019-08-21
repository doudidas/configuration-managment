#!/bin/bash
git add --all

majVersion=$(cat ./version.txt | cut -d'.' -f1)
minVersion=$(cat ./version.txt | cut -d'.' -f2)

response=$1
while [[ $response =~ ^[^yYnN]$ ]]
do
    echo "Are you doing a major update ?: [y/n]"
    read  response
done

if [ $response = "y" ]
then
    majVersion=$((majVersion + 1))
    minVersion=0
else
    minVersion=$((minVersion + 1))
fi

git commit -m 'version: '$majVersion'.'$minVersion

