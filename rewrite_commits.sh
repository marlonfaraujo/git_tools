#!/bin/bash
set -e

# Current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# Example of changing the date: sets all commits to now
# (can be adjusted for specific dates)
NEW_DATE=$(date +"%Y-%m-%dT%H:%M:%S")

git filter-repo --commit-callback '
import os
from datetime import datetime

branch = os.environ.get("BRANCH_NAME")
new_date = os.environ.get("NEW_DATE")

# Update dates (author and committer)
commit.author_date = new_date
commit.committer_date = new_date

# Append branch name at the end of the commit message
if f"[{branch}]" not in commit.message.decode("utf-8"):
    commit.message = (commit.message.decode("utf-8").strip() + f" [{branch}]").encode("utf-8")
' --force
