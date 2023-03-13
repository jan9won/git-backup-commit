# --------------------------------------------------------------------------- #
# Is correct remote repository name is set in local git config?
# 
# 1. exit 1 when no remote set
# 2. ask user for remote name if there's remote yet no config set
# 3. exit 1 if remote is not accessible
# 4. exit 0 when success
# --------------------------------------------------------------------------- #

# Lookup config for variable remote-name
BACKUP_REMOTE_NAME=$(git config --get git-backup.remote-name)
# Get remote names
REMOTES=($(git remote))
NUMBER_OF_REMOTES=${#REMOTES[@]}

# If no remote repository, abort.
if [[ $NUMBER_OF_REMOTES = 0 ]]; then
	printf "No remote repository set yet.\nSet remote repository for backup first."
	exit 1
fi

# Does this remote actually exists?
does_remote_exist(){
	printf "Checking if the remote \"$BACKUP_REMOTE_NAME\" is accessible...\n"
	timeout 10 git ls-remote $BACKUP_REMOTE_NAME 1>/dev/null
	if [[ $? != 0 ]]; then
		exit 1
	else
		echo "Remote repository \"$BACKUP_REMOTE_NAME\" exists and accessible."
		git config git-backup.remote-name $BACKUP_REMOTE_NAME
		exit 0
	fi 
}

# Request user to select one of the remote names.
get_backup_remote_name(){
	printf "Enter one of your remote's name to use it for backup ["
	for i in "${!REMOTES[@]}"; do
		printf "${REMOTES[$i]}";
		if (( $NUMBER_OF_REMOTES > $i + 1 )); then
			printf " / "
		fi
	done
	printf "] : "
	read BACKUP_REMOTE_NAME

	local BACKUP_REMOTE_NAME_EXISTS=false
	for remote in ${REMOTES[@]}; do
		[[ $BACKUP_REMOTE_NAME = $remote ]] && BACKUP_REMOTE_NAME_EXISTS=true
	done

	if [[ $BACKUP_REMOTE_NAME_EXISTS = false ]]; then
		printf "There's no remote named \"$BACKUP_REMOTE_NAME\"\n"
		get_backup_remote_name
		else
		does_remote_exist
	fi
}

# If no config for git-backup.remote-name, request user.
if [[ $BACKUP_REMOTE_NAME ]]; then
	does_remote_exist
	else
	printf "Backup remote's name is not configured in git config.\n"
	get_backup_remote_name
fi
