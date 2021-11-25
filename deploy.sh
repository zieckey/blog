#!/bin/bash

# 注意，需要先更新 public 目标到最新状态，在blog当前目录下进行如下操作
# cd public
# git submodule init
# git submodule update // 这样能把public目标更新到跟 git@github.com:zieckey/zieckey.github.io.git 一致




echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi

# Push Hugo content
# git add -A
git st
git commit -a -m "$msg"
git st
git push origin master


# Build the project.
#hugo --theme=hyde
hugo --theme=hyde --baseUrl="http://blog.codeg.cn/"
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
git commit -a -m "Update submodule : public"
git push origin master
