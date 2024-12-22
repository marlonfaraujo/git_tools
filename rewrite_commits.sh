#!/bin/bash
set -e

# Current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# Starting date for the first commit (can be adjusted)
START_DATE=$(date -d "2025-09-01 09:00:00" +"%Y-%m-%dT%H:%M:%S")

# Time increment in hours between commits (e.g., 2 hours)
HOURS_INCREMENT=2

# Convert hours to seconds
INCREMENT=$((HOURS_INCREMENT * 3600))

# Counter to increment each commit
COUNTER=0

git filter-repo --commit-callback '
import os
from datetime import datetime, timedelta

branch = os.environ.get("BRANCH_NAME")
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

# Prepend branch name to commit message if not already there
msg = commit.message.decode("utf-8").strip()
if not msg.startswith(f"[{branch}]"):
    commit.message = f"[{branch}] {msg}".encode("utf-8")

# Increment counter for next commit
os.environ["COUNTER"] = str(counter + 1)
' --force
