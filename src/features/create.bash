backup_branch_name=backup-$(date +%s); 
git switch -c "$backup_branch_name"; 
git add .; 
git commit -m "$backup_branch_name"
git switch -
git restore --source "$backup_branch_name" .