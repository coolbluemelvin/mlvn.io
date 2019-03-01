#!/bin/bash

echo -e "\033[0;32mDeploying new blog...\033[0m"

echo -e "\033[0;32mDeleting old site...\033[0m"
rm -rf ~/src/coolbluemelvin.github.io/posts/

echo -e "\033[0;32mRunning hugo...\033[0m"
hugo -d ../coolbluemelvin.github.io

echo -e "\033[0;32mChanging to blog directory...\033[0m"
cd ../coolbluemelvin.github.io

echo -e "\033[0;32mCommit and push the new build to coolbluemelvin.github.io...\033[0m"
git add .
git commit -am "New Blog Build (`date`)"
git push

echo -e "\033[0;32mChange back to mlvn.io...\033[0m"
cd ../mlvn.io

echo -e "\033[0;32mCommit and push the new build to mlvn.io...\033[0m"
git add -A 
git commit -am "New Blog Build (`date`)"
git push

echo -e "\033[0;32mDeploy complete.\033[0m"
