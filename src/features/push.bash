#!/usr/bin/env bash
echo "push.bash: $@"

# current_branch_name=$(git branch --show-current); 
# backup_branch_name=backup-$(date +%s); 
# git switch -c "$backup_branch_name"; 
# git add .; 
# git commit -m "$backup_branch_name" && git push backup "$backup_branch_name"; 
# git switch "$current_branch_name"; 
# git restore --source "$backup_branch_name" .;; 