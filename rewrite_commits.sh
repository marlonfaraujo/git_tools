#!/bin/bash
set -e

# File with commit customization
CONFIG_FILE="commit_references.json"

git filter-repo --commit-callback "
import os, json
from datetime import datetime

config_file = os.environ.get('CONFIG_FILE', 'commit_references.json')

# Load commit references JSON
with open(config_file, 'r', encoding='utf-8') as f:
    commit_rules = json.load(f)

commit_idx = str(commit.original_id.decode('utf-8'))

# Get rules if exist
rule = commit_rules.get(commit_idx, {})

# Handle commit date (if present in JSON)
if 'date' in rule and rule['date']:
    try:
        new_date = datetime.strptime(rule['date'], '%Y-%m-%d %H:%M:%S')
        commit_date_str = new_date.strftime('%Y-%m-%dT%H:%M:%S')
        commit.author_date = commit_date_str
        commit.committer_date = commit_date_str
    except Exception as e:
        pass  # ignore invalid date

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

done

echo "✅ All branches have been rewritten."
echo "📊 Total commits processed: based on existing commits in the repository"
