#!/bin/bash
set -e

# Current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# Starting day for commits (can be adjusted)
START_DAY="2025-09-01"

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
import random
from datetime import datetime, timedelta

branch = os.environ.get("BRANCH_NAME")
branch_type = os.environ.get("BRANCH_TYPE")
start_day = os.environ.get("START_DAY")

# Randomize starting hour and minute for the first commit
if "COMMIT_COUNT" not in os.environ:
    os.environ["COMMIT_COUNT"] = "0"
    start_hour = random.randint(9, 17)          # Working hours: 09-17
    start_minute = random.randint(0, 59)
    os.environ["START_HOUR"] = str(start_hour)
    os.environ["START_MINUTE"] = str(start_minute)

commit_count = int(os.environ.get("COMMIT_COUNT"))
start_hour = int(os.environ.get("START_HOUR"))
start_minute = int(os.environ.get("START_MINUTE"))

# Random offset in minutes for this commit (0-59)
random_minutes = random.randint(0, 59)
random_seconds = random.randint(0, 59)

# Calculate commit datetime
base_dt = datetime.strptime(start_day, "%Y-%m-%d") \
          + timedelta(hours=start_hour, minutes=start_minute) \
          + timedelta(minutes=random_minutes, seconds=random_seconds)

commit_date_str = base_dt.strftime("%Y-%m-%dT%H:%M:%S")

# Update commit dates
commit.author_date = commit_date_str
commit.committer_date = commit_date_str

# Prepend branch type and name to commit message if not already there
msg = commit.message.decode("utf-8").strip()
prefix = f"[{branch_type}/{branch}]"
if not msg.startswith(prefix):
    commit.message = f"{prefix} {msg}".encode("utf-8")

# Increment commit count for next commit
os.environ["COMMIT_COUNT"] = str(commit_count + 1)
' --force
