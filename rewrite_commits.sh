#git remote add origin <URL>
#git filter-repo
#git push --set-upstream origin main --force
#!/bin/bash
set -e

read -p "Enter repository URL: " url

if [ -z "$url" ]; then
  echo "No URL provided."
  exit 1
fi

# File with commit customization
CONFIG_FILE="commit_references.json"

# Increment to use when JSON date is empty
INCREMENT_HOURS=1
INCREMENT_MINUTES=22

# Keep track of the last used date
LAST_USED_DATE=""

git filter-repo --commit-callback "
import os, json, time
from datetime import datetime, timedelta

config_file = os.environ.get('CONFIG_FILE', 'commit_references.json')
increment_hours = int(os.environ.get('INCREMENT_HOURS', 1))
increment_minutes = int(os.environ.get('INCREMENT_MINUTES', 22))

# Load commit references JSON
with open(config_file, 'r', encoding='utf-8') as f:
    commit_rules = json.load(f)

# Initialize global variable for last used datetime
if 'last_used_date' not in globals():
    globals()['last_used_date'] = None

# Get current commit index
if 'commit_index' not in globals():
    globals()['commit_index'] = 0
else:
    globals()['commit_index'] += 1

commit_idx = str(globals()['commit_index'])

# Fetch rule from JSON
rule = commit_rules.get(commit_idx, {})

# Determine commit date
new_datetime = None
if 'date' in rule and rule['date']:
    try:
        new_datetime = datetime.strptime(rule['date'], '%Y-%m-%d %H:%M:%S')
    except Exception as e:
        pass  # ignore invalid date

if not new_datetime:
    # If last used date exists, add increment
    if globals()['last_used_date']:
        new_datetime = globals()['last_used_date'] + timedelta(hours=increment_hours, minutes=increment_minutes)
    else:
        # Look for previous commits with filled dates
        previous_indices = list(commit_rules.keys())
        # Keeps in the natural order that comes in JSON
        for idx in reversed(previous_indices):
            if idx == commit_idx:
                continue
            prev_rule = commit_rules.get(idx, {})
            if 'date' in prev_rule and prev_rule['date']:
                try:
                    new_datetime = datetime.strptime(prev_rule['date'], '%Y-%m-%d %H:%M:%S') + timedelta(hours=increment_hours, minutes=increment_minutes)
                    break
                except:
                    continue
    # If still None, keep original commit date
    if not new_datetime:
        new_datetime = commit.author_date.decode('utf-8')  # fallback to original
        try:
            new_datetime = datetime.strptime(new_datetime, '%s')
        except:
            new_datetime = None  # leave unchanged if parsing fails

# Update last used date
globals()['last_used_date'] = new_datetime

# Apply new date if valid
if isinstance(new_datetime, datetime):
    timestamp = int(new_datetime.timestamp())
    timezone_offset = '-0300'
    commit.author_date = f'{timestamp} {timezone_offset}'.encode('utf-8')
    commit.committer_date = f'{timestamp} {timezone_offset}'.encode('utf-8')

# Handle commit message
original_msg = commit.message.decode('utf-8').strip()
new_msg = original_msg

# If JSON provides a full message, replace it
if 'message' in rule and rule['message']:
    new_msg = rule['message']
else:
    prefix_type = rule.get('prefix_type', '')
    branch_name = rule.get('branch_name', '')

    # Skip prefixes for main, master, develop or merges
    if prefix_type and branch_name:
        lowered = branch_name.lower()
        if not (lowered in ['main', 'master', 'develop'] or original_msg.lower().startswith('merge')):
            new_msg = f'[{prefix_type}/{branch_name}] {original_msg}'

commit.message = new_msg.encode('utf-8')
" --force

if git remote | grep -q "^origin$"; then
  git remote remove origin
fi

git remote add origin "$url"

branch=$(git branch --show-current)

git push --set-upstream origin "$branch" --force

echo "✅ All branches have been rewritten."
echo "📊 Total commits processed: based on existing commits in the repository"

echo "Done. Branch '$branch' is now tracking '$url'."

