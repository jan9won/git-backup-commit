# --------------------------------------------------------------------------- #
# Is correct remote for backup set in local config file?
# --------------------------------------------------------------------------- #

# Lookup config
BACKUP_REMOTE_NAME=$(git config --get git-backup.remote-name)
# Get remote names
REMOTES=($(git remote))
NUMBER_OF_REMOTES=${#REMOTES[@]}

# If no remote repository, abort.
if [[ $NUMBER_OF_REMOTES = 0 ]]; then
	printf "No remote repository set yet.\n"
	exit 1
else
	# Else check if it's reachable
	does_remote_exist
fi

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
		printf "There's no remote named $BACKUP_REMOTE_NAME."
		get_backup_remote_name
	fi
}

# If no config for git-backup.remote-name, request user.
if [[ -z $BACKUP_REMOTE_NAME ]]; then
	printf "Backup remote's name is not configured in git config.\n"
	get_backup_remote_name
fi

# Does this remote actually exists?
does_remote_exist(){
	printf "Checking if the remote repository is accessible...\n"
	timeout 10 git ls-remote $BACKUP_REMOTE_NAME 1>/dev/null
		
	if [[ $BACKUP_REMOTE_EXISTS != 0 ]]; then
		exit 
	fi 
}