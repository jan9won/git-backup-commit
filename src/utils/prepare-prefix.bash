
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
	SOURCE=$(readlink "$SOURCE")
	[[ $SOURCE != /* ]] && SOURCE=$SCRIPT_PATH/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

# --------------------------------------------------------------------------- #
# Is correct branch prefix is set in local git config?
# --------------------------------------------------------------------------- #

PATTERN="^[a-z0-9][a-z0-9\-]+[a-z0-9]$"
# Lookup config
BACKUP_BRANCH_WAS_SET=3
BACKUP_BRANCH_PREFIX=$(git config --get git-backup.branch-prefix)
BACKUP_BRANCH_PREFIX_FIXED=""
BACKUP_BRANCH_PREFIX_FIXED_ACCEPT="n"


# Request user to select one of the remote names.
get_backup_branch_prefix(){
	printf "Enter prefix for backup branches (Allowed pattern is \"$PATTERN\" :"
	read BACKUP_BRANCH_PREFIX
	is_prefix_correct
}

# compare string with pattern, clean the string.
is_prefix_correct(){
	if [[ $BACKUP_BRANCH_PREFIX =~ $PATTERN ]]; then
		# if string matches pattern, set config
		git config git-backup.branch-prefix $BACKUP_BRANCH_PREFIX
		if [[ BACKUP_BRANCH_WAS_SET = 3 ]]; then
			printf "Prefix for backup branches is set to \"$BACKUP_BRANCH_PREFIX\"\n"
		fi
		exit $BACKUP_BRANCH_WAS_SET
	else
		# if string doesn't match pattern, clean the string, ask accept/reject
		printf "\"$BACKUP_BRANCH_PREFIX\" has illegal pattern\n"
		BACKUP_BRANCH_PREFIX_FIXED=$(fix_prefix "$BACKUP_BRANCH_PREFIX")
		printf "Would you use auto-fixed one \"$BACKUP_BRANCH_PREFIX_FIXED\" ?\n"
		$SCRIPT_PATH/read-yes-or-no.bash
		BACKUP_BRANCH_PREFIX_FIXED_ACCEPT=$?

		if [[ $BACKUP_BRANCH_PREFIX_FIXED_ACCEPT = 0 ]]; then
			# if accepted, set config
			git config git-backup.branch-prefix $BACKUP_BRANCH_PREFIX_FIXED
			printf "Prefix for backup branches is set to \"$BACKUP_BRANCH_PREFIX\"\n"
			exit $BACKUP_BRANCH_WAS_SET
		else
			# if rejected, request for new string
			get_backup_branch_prefix
		fi
	fi
}

# make lowercase, replace illegal characters with "-", remove duplicate "-"
fix_prefix(){
	echo "$BACKUP_BRANCH_PREFIX" |
	tr '[:upper:]' '[:lower:]' |
	sed -r 's/[^a-zA-Z0-9]/-/g' |
	sed -e 's/--*/-/g' |
	sed -e 's/^-//g; s/-$//g'
}

# If no config for git-backup.remote-name, request user.
if [[ -z $BACKUP_BRANCH_PREFIX ]]; then
	printf "Backup branches' prefix is not configured in git config.\n"
	get_backup_branch_prefix
# If config exists, check for illegal characters
else
	BACKUP_BRANCH_WAS_SET=0
	is_prefix_correct
fi