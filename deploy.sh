#!/bin/bash
echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi

# Push Hugo content
git add -A
git st
git commit -m "$msg"
git st
git push origin master


# Build the project.
hugo --theme=hugo-rapid-theme
sleep 1
git st

# Go To Public folder
cd public
git st
# Add changes to git.
git add -A
git st

# Commit changes.
git commit -a -m "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ..