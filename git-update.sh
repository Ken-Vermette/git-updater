#!/bin/bash

# Updates various git repositories registered in ~/git-update-locations.ini.
# Format is as follows:
# [MyProject]
# firstRepo=/path/to/first/repo
# secondRepo=/path/to/second/repo
# allRepos=/path/to/repos/*
#
# git-update.sh MyProject firstRepo
# git-update.sh MyProject allRepos
#
# If the value of a path ends with "*" it will look at all directories in that
# location, if they have a git repo, it will run the pull.
#
# For example:
# 
# [mywordpresssite.com]
# theme=/var/www/mywordpresssite.com/public_html/wp-content/themes/my-git-theme
# plugins=/var/www/mywordpresssite.com/public_html/wp-content/plugins/*
#
# git-update.sh mywordpresssite.com theme
# -> will update the theme from git.
#
# git-update.sh mywordpresssite.com plugins
# -> will update all plugins found connected to git.

if [ ! -f "$HOME/git-update-locations.ini" ]; then
	"$HOME/git-update-locations.ini not found"
	exit
fi

if [[ -z $1 ]] ; then
	echo "You must specify a registered site"
	exit
fi

if [[ -z $2 ]] ; then
	echo "You must specify a section to update"
	exit
fi

SECTION=${1//[_- ]/.}
TARGET=${2//[._ -]/"-"}
CONFIG="$HOME/git-update-locations.ini"
FOLDER=$(sed -nr "/^\[$SECTION\]/ { :l /^$TARGET[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" "$CONFIG")

if [ "$FOLDER" = "" ]; then
	echo "Target $SECTION $TARGET not found."
	exit
fi

if [[ "$FOLDER" =~ '*'$ ]] ; then 
	echo "Scanning for git repositories"
	for REPO in "${FOLDER::-1}"*; do
		[ -d "$REPO" ] || continue
		cd "$REPO"
		status="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
		[ "$status" = "true" ] || continue
		echo "Updating $REPO"
		git status -s
		git pull --verbose
	done
else
	echo "Updating $FOLDER"
	cd "$FOLDER"
	git status -s
	git pull --verbose
fi