#!/usr/bin/env bash

echo "Committing code and pushing to Git, which should trigger your Azure DevOps CI process..."

git add .
git commit -m "Update"
git push