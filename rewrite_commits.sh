#!/bin/bash
set -e

# Current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# Starting date for the first commit
START_DATE=$(date -d "2025-09-01 09:00:00" +"%Y-%m-%dT%H:%M:%S")

# Time increment in hours between commits
HOURS_INCREMENT=2
INCREMENT=$((HOURS_INCREMENT * 3600))

# Counter to increment each commit
COUNTER=0

# Determine branch type for Git Flow
if [[ "$BRANCH_NAME" == develop ]]; then
    BRANCH_TYPE="develop"
elif [[ "$BRANCH_NAME" == main || "$BRANCH_NAME" == master ]]; then
    BRANCH_TYPE="main"
elif [[ "$BRANCH_NAME" == feature/* ]]; then
    BRANCH_TYPE="feature"
elif [[ "$BRANCH_NAME" == release/* ]]; then
    BRANCH_TYPE="release"
elif [[ "$BRANCH_NAME" == hotfix/* ]]; then
    BRANCH_TYPE="hotfix"
else
    BRANCH_TYPE="other"
fi

git filter-repo --commit-callback '
import os
from datetime import datetime, timedelta

branch = os.environ.get("BRANCH_NAME")
branch_type = os.environ.get("BRANCH_TYPE")
start_date = os.environ.get("START_DATE")
increment = int(os.environ.get("INCREMENT"))
counter = int(os.environ.get("COUNTER"))

# Calculate new date for this commit
base_dt = datetime.strptime(start_date, "%Y-%m-%dT%H:%M:%S")
new_dt = base_dt + timedelta(seconds=counter * increment)
commit_date_str = new_dt.strftime("%Y-%m-%dT%H:%M:%S")

# Update commit dates
commit.author_date = commit_date_str
commit.committer_date = commit_date_str

# Prepend branch type and name to commit message if not already there
msg = commit.message.decode("utf-8").strip()
prefix = f"[{branch_type}/{branch}]"
if not msg.startswith(prefix):
    commit.message = f"{prefix} {msg}".encode("utf-8")

# Increment counter for next commit
os.environ["COUNTER"] = str(counter + 1)
' --force
