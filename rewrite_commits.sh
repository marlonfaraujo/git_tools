#!/bin/bash
set -e

# Current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# Time interval
START_DATE="2025-08-23 08:21:00"
END_DATE="2025-08-25 23:59:00"

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
start_date = datetime.strptime(os.environ.get("START_DATE"), "%Y-%m-%d %H:%M:%S")
end_date = datetime.strptime(os.environ.get("END_DATE"), "%Y-%m-%d %H:%M:%S")

# On first commit, calculate interval per commit
if "TOTAL_COMMITS" not in os.environ:
    os.environ["TOTAL_COMMITS"] = str(commit.repo.get_number_of_commits())
    os.environ["COMMIT_INDEX"] = "0"

total_commits = int(os.environ.get("TOTAL_COMMITS"))
commit_index = int(os.environ.get("COMMIT_INDEX"))

# Linear distribution of commits across interval
delta = (end_date - start_date) / max(total_commits - 1, 1)
commit_dt = start_date + commit_index * delta
commit_date_str = commit_dt.strftime("%Y-%m-%dT%H:%M:%S")

# Update commit dates
commit.author_date = commit_date_str
commit.committer_date = commit_date_str

# Commit message adjustments
msg = commit.message.decode("utf-8").strip()

is_merge = msg.startswith("Merge ")
skip_prefix = branch_type in ["main", "develop"] or is_merge

if not skip_prefix:
    prefix = f"[{branch_type}/{branch}]"
    if not msg.startswith(prefix):
        msg = f"{prefix} {msg}"

commit.message = msg.encode("utf-8")

# Increment commit index
os.environ["COMMIT_INDEX"] = str(commit_index + 1)
' --force
