#!/usr/bin/env bash

# --------------------------------------------------------------------------- #
# Get install script's absolute path
# --------------------------------------------------------------------------- #
# 1. Resolve $SOURCE until the file is no longer a symlink.
# 2. If $SOURCE was a relative symlink, resolve it relative to the symlink.
# --------------------------------------------------------------------------- #

SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do
	INSTALL_SCRIPT_DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
	SOURCE=$(readlink "$SOURCE")
	[[ $SOURCE != /* ]] && SOURCE=$INSTALL_SCRIPT_DIR/$SOURCE 
done
INSTALL_SCRIPT_DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

# --------------------------------------------------------------------------- #
# Check if git is installed
# --------------------------------------------------------------------------- #

git_installed=$(git --version > /dev/null  2>&1; printf $?)
if [[ ! $git_installed -eq 0 ]]; then
	printf "Git is not installed or something's wrong with your installed git.\n"
	exit 1
fi

# --------------------------------------------------------------------------- #
# Copy script source directory to $HOME/lib
# --------------------------------------------------------------------------- #

SCRIPT_DIRECTORY_NAME="git-backup"
DUPLICATE_DIRECTORY_NAME=""

get_script_directory_name(){
	printf "Overwrite [o] / Create new directory [c] / Exit [x] : "
	read SCRIPT_DIRECTORY_NAME_OPTION
	if [[ $SCRIPT_DIRECTORY_NAME_OPTION = "o" ]]; then
		true
	elif [[ $SCRIPT_DIRECTORY_NAME_OPTION = "c" ]]; then
		printf "Enter library directory name : "
		read SCRIPT_DIRECTORY_NAME
		check_script_directory_duplicate
	elif [[ $SCRIPT_DIRECTORY_NAME_OPTION = "x" ]]; then
		printf "Exiting installaion process\n"
		exit
	else
		printf "Invalid input\n"
		get_script_directory_name
	fi
}

check_script_directory_duplicate(){
	if [ -d $HOME/lib/$SCRIPT_DIRECTORY_NAME ]; then
		DUPLICATE_DIRECTORY_NAME="$HOME/lib/$SCRIPT_DIRECTORY_NAME"
		printf "\nLibrary directory $DUPLICATE_DIRECTORY_NAME already exists.\n"
		get_script_directory_name
	fi
}

check_script_directory_duplicate
if [[ (! -z $DUPLICATE_DIRECTORY_NAME) && $SCRIPT_DIRECTORY_NAME_OPTION = "o" ]]; then
	printf "Removing existing directory $DUPLICATE_DIRECTORY_NAME\n"
	rm -rf $HOME/lib/$SCRIPT_DIRECTORY_NAME
fi
printf "Writing a directory $HOME/lib/$SCRIPT_DIRECTORY_NAME\n"
mkdir -p $HOME/lib/$SCRIPT_DIRECTORY_NAME
cp -r $INSTALL_SCRIPT_DIR/src/* $HOME/lib/$SCRIPT_DIRECTORY_NAME
chmod -R 755 $HOME/lib/$SCRIPT_DIRECTORY_NAME

# --------------------------------------------------------------------------- #
# Add symlink of entry script to $HOME/bin
# --------------------------------------------------------------------------- #

SYMLINK_NAME="git-backup"
SYMLINK_NAME_DUPLICATE=""

get_symlink_name(){
	printf "Overwrite [o] / Create new symlink [c] / Exit [x] : "
	read SYMLINK_NAME_OPTION
	if [[ $SYMLINK_NAME_OPTION = "o" ]]; then
		true
	elif [[ $SYMLINK_NAME_OPTION = "c" ]]; then
		printf "Enter symlink name : "
		read SYMLINK_NAME
		check_symlink_duplicate
	elif [[ $SYMLINK_NAME_OPTION = "x" ]]; then
		printf "Exiting installaion process\n"
		exit
	else
		printf "Invalid input\n"
		get_script_directory_name
	fi
}

check_symlink_duplicate(){
	if [ -e "$HOME/bin/$SYMLINK_NAME" ]; then
		SYMLINK_NAME_DUPLICATE="$HOME/bin/$SYMLINK_NAME"
		printf "\nFile named $SYMLINK_NAME already exists in \$HOME/bin.\n"
		get_symlink_name
	fi
}

check_symlink_duplicate
if [[ (! -z $SYMLINK_NAME_DUPLICATE) && $SYMLINK_NAME_OPTION = "o" ]]; then
	printf "Removing existing file $SYMLINK_NAME_DUPLICATE\n"
	rm $SYMLINK_NAME_DUPLICATE
fi
printf "Writing symlink $HOME/bin/$SYMLINK_NAME\n"
ln -s $HOME/lib/$SCRIPT_DIRECTORY_NAME/entry.bash $HOME/bin/$SYMLINK_NAME

# --------------------------------------------------------------------------- #
# Add $HOME/bin to $PATH
# --------------------------------------------------------------------------- #

mkdir -p $HOME/bin
touch $HOME/.bash_profile
if ! grep -Fxq "PATH=\$PATH:\$HOME/bin" $HOME/.bash_profile; then
	printf "PATH=\$PATH:\$HOME/bin\n" >> $HOME/.bash_profile
fi

# --------------------------------------------------------------------------- #
# Add alias calling entry script to global git config.
# --------------------------------------------------------------------------- #

ALIAS_NAME="backup"

get_alias_name(){
	printf "Overwrite [o] / Create new alias [c] / Exit [x] : "
	read ALIAS_NAME_OPTION
	if [[ $ALIAS_NAME_OPTION = "o" ]]; then
		true
	elif [[ $ALIAS_NAME_OPTION = "c" ]]; then
		printf "Enter symlink name : "
		read ALIAS_NAME
		check_alias_duplicate
	elif [[ $ALIAS_NAME_OPTION = "x" ]]; then
		printf "Exiting installaion process\n"
		exit
	else
		printf "Invalid input\n"
		get_alias_name
	fi
}

check_alias_duplicate(){
	if [ ! -z $(git config --get alias.$ALIAS_NAME) ]; then
		printf "\nGit alias named '$ALIAS_NAME' already in your git config.\n"
		get_alias_name
	fi
}

check_alias_duplicate
printf "Writing to git config : alias.$ALIAS_NAME\n"
git config --global "alias.$ALIAS_NAME" "!$SYMLINK_NAME"
