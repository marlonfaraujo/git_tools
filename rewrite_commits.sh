#!/bin/bash
set -e

# ==============================
# Script to rewrite commits
# in ALL repo branches,
# applying Git Flow convention
# Distributes commits across the specified dates
# ==============================

# Start and end datetime
START_DATETIME="2025-08-23 08:21"
END_DATETIME="2025-08-25 23:59:57"

# Total number of commits to distribute
TOTAL_COMMITS=77

# List all local branches
BRANCHES=$(git for-each-ref --format='%(refname:short)' refs/heads/)

# Count the total number of commits in all branches
echo "🔍 Checking total commits..."
ACTUAL_COMMIT_COUNT=0
for BRANCH in $BRANCHES; do
  git checkout "$BRANCH" --quiet
  COMMIT_COUNT=$(git rev-list --count HEAD)
  ACTUAL_COMMIT_COUNT=$((ACTUAL_COMMIT_COUNT + COMMIT_COUNT))
done

echo "📊 Total commits found: $ACTUAL_COMMIT_COUNT"
echo "🎯 Expected commits: $TOTAL_COMMITS"

if [ $ACTUAL_COMMIT_COUNT -ne $TOTAL_COMMITS ]; then
  echo "⚠️  Warning: The number of commits ($ACTUAL_COMMIT_COUNT) does not match the expected ($TOTAL_COMMITS)"
  echo "The script will continue and distribute the existing commits within the specified period."
fi

for FULL_BRANCH in $BRANCHES; do
  echo "🔄 Rewriting branch: $FULL_BRANCH"

  git checkout "$FULL_BRANCH" --quiet

  # Extract branch type and name
  BRANCH_TYPE=$(echo "$FULL_BRANCH" | cut -d'/' -f1)
  BRANCH_NAME=$(echo "$FULL_BRANCH" | cut -d'/' -f2-)
  # If there is no slash, use the full name
  if [[ "$FULL_BRANCH" != */* ]]; then
    BRANCH_NAME="$FULL_BRANCH"
  fi
  # Ensure BRANCH_NAME is never empty
  if [[ -z "$BRANCH_NAME" ]]; then
    BRANCH_NAME="$FULL_BRANCH"
  fi

  # If branch is master, main or develop → do not apply semantic commit
  if [[ "$FULL_BRANCH" == "master" || "$FULL_BRANCH" == "main" || "$FULL_BRANCH" == "develop" ]]; then
    PREFIX_TYPE="none"
  else
    case "$BRANCH_TYPE" in
      feature) PREFIX_TYPE="feature" ;;
      hotfix)  PREFIX_TYPE="hotfix" ;;
      release) PREFIX_TYPE="release" ;;
      *) echo "⚠️ Unrecognized type in $FULL_BRANCH. Using 'chore'."; PREFIX_TYPE="chore" ;;
    esac
  fi

  # Export environment variables
  export PREFIX_TYPE
  export BRANCH_NAME
  export START_DATETIME
  export END_DATETIME
  export TOTAL_COMMITS

  git filter-repo --commit-callback "
import os, random, json
from datetime import datetime, timedelta

start_datetime_str = os.environ.get('START_DATETIME')
end_datetime_str = os.environ.get('END_DATETIME')
total_commits = int(os.environ.get('TOTAL_COMMITS'))

start_datetime = datetime.strptime(start_datetime_str, '%Y-%m-%d %H:%M')
end_datetime = datetime.strptime(end_datetime_str, '%Y-%m-%d %H:%M:%S')
total_minutes = int((end_datetime - start_datetime).total_seconds() / 60)

# Initialize global commit counter
if 'global_commit_index' not in globals():
  globals()['global_commit_index'] = 0
else:
  globals()['global_commit_index'] += 1

if total_commits > 1:
  minutes_per_commit = total_minutes / (total_commits - 1)
else:
  minutes_per_commit = 0

commit_index = globals()['global_commit_index']
commit_minutes = commit_index * minutes_per_commit
new_datetime = start_datetime + timedelta(minutes=commit_minutes)
random_minute_variation = random.randint(-5, 5)
random_second_variation = random.randint(0, 59)
new_datetime += timedelta(minutes=random_minute_variation, seconds=random_second_variation)

if new_datetime < start_datetime:
  new_datetime = start_datetime
elif new_datetime > end_datetime:
  new_datetime = end_datetime

import time
timestamp = int(new_datetime.timestamp())
timezone_offset = '-0300'

commit.author_date = f'{timestamp} {timezone_offset}'.encode('utf-8')
commit.committer_date = f'{timestamp} {timezone_offset}'.encode('utf-8')

msg = commit.message.decode('utf-8').strip()

# Detect merge and main branches
is_merge = msg.lower().startswith('merge') or 'merge' in msg.lower()

# Read the prefix array from the external file
prefixes_path = 'commit_prefixes.json'
if os.path.exists(prefixes_path):
  with open(prefixes_path, 'r', encoding='utf-8') as f:
    commit_prefixes = json.load(f)
else:
  commit_prefixes = {}

prefix_type = ''
branch_name = ''
if str(commit_index) in commit_prefixes:
  prefix_type = commit_prefixes[str(commit_index)].get('prefix_type', '')
  branch_name = commit_prefixes[str(commit_index)].get('branch_name', '')

is_main_branch = (prefix_type == 'none')

import re
# Apply semantics only if not merge nor main/master/develop and if prefix_type/branch_name are not empty
if not is_merge and not is_main_branch and prefix_type and branch_name:
  msg = re.sub(r'^(feat|feature|hotfix|release|chore|fix|docs|style|refactor|test)\([^)]+\):\s*', '', msg)
  prefix = f'{prefix_type}({branch_name}): '
  msg = prefix + msg

commit.message = msg.encode('utf-8')

commit_time_str = new_datetime.strftime('%Y-%m-%d %H:%M:%S')
print(f'Commit #{commit_index:2d}: {commit_time_str} - {msg[:50]}...')
" --force

done

echo "✅ All branches have been rewritten."
echo "📅 Commits distributed between $START_DATETIME and $END_DATETIME"
echo "📊 Total commits processed: based on existing commits in the repository"
