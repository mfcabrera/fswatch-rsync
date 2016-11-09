#!/bin/bash

# @author Clemens Westrup (some modifications by Miguel Cabrera)
# @date 07.07.2014

# This is a script to automatically synchronize a local project folder to a
# folder on a cluster server.
# It watches the local folder for changes and recreates the local state on the
# target machine as soon as a change is detected.

# For setup and usage see README.md

################################################################################

PROJECT="fswatch-rsync"
VERSION="0.2.0"

# Set up your path to fswatch here if you don't want to / can't add it
# globally to your PATH variable (default is "fswatch" when specified in PATH).
# e.g. FSWATCH_PATH="/Users/you/builds/fswatch/fswatch"
#FSWATCH_PATH="/Users/cwestrup/extracted_source_builds/fswatch/fswatch"

# Sync latency / speed in seconds
LATENCY="1"

# default server setup
TARGET="vmx" # target ssh server

# check color support
colors=$(tput colors)
if (($colors >= 8)); then
    red='\033[0;31m'
    green='\033[0;32m'
    nocolor='\033[00m'
else
  red=
  green=
  nocolor=
fi

while getopts ":d" opt; do
  case $opt in
    d)
        #echo "-d was triggered!" >&2
        DELETE_TARGET="1"
        shift
        ;;

    --) # End of all options
	  shift ; break
  esac
done


# Check compulsory arguments
if [[ "$1" = "" || "$2" = "" || "$3" = "" ]]; then
  echo -e "${red}Error: $PROJECT takes 3 compulsory arguments.${nocolor}"
  echo "Usage: fswatch-rsync.sh [-d] /local/path /targetserver/path ssh_user targetserver"
  echo "[targetserver] "
  echo "If -d is used, then the target directory is delted and a full sync is done"

  exit
else
  LOCAL_PATH="$1"
  TARGET_PATH="$2"
  SSH_USER="$3"
fi





# Check optional arguments
# if [[ "$4" != "" ]]; then
#  MIDDLE="$4"
# fi
if [[ "$4" != "" ]]; then
  TARGET="$4"
fi
if [[ "$5" != "" ]]; then
  TARGET_SSH_USER="$5"
else
  TARGET_SSH_USER="$SSH_USER"
fi

# Welcome
echo      ""
echo -e   "${green}Hei! This is $PROJECT v$VERSION.${nocolor}"
echo      "Local source path:  \"$LOCAL_PATH\""
echo      "Remote target path: \"$TARGET_PATH\""
echo      "To target server:   \"$TARGET_SSH_USER@$TARGET\""
echo      ""
if [ "$DELETE_TARGET" = "1" ]; then
   echo -n   "Performing initial complete synchronization "
   echo -n   "(Warning: Target directory will be overwritten "
   echo      "with local version if differences occur)."
# Perform initial complete sync
   read -n1 -r -p "Press any key to continue (or abort with Ctrl-C)... " key
   echo      ""
   echo -n   "Synchronizing... "
   echo -n "rsync -avzr -q --delete --force  \
           $LOCAL_PATH $TARGET_SSH_USER@$TARGET:$TARGET_PATH "
           rsync -avzr -q --delete --force --exclude=".*" --exclude "training" \
           $LOCAL_PATH $TARGET_SSH_USER@$TARGET:$TARGET_PATH
           echo      "done."
           echo      ""

fi

# Watch for changes and sync (exclude hidden files)
echo    "Watching for changes. Quit anytime with Ctrl-C."
fswatch -0 -r -l $LATENCY $LOCAL_PATH --exclude="/\.[^/]*$"  --exclude="*.pack" --exclude "*_flymake*"  \
| while read -d "" event
  do
    echo $event > .tmp_files
    echo -en "${green}" `date` "${nocolor}\"$event\" changed. Synchronizing... "
    rsync -avzr -q --cvs-exclude --exclude='.*' --exclude '*_flymake.py'  \
    --include-from=.tmp_files \
    $LOCAL_PATH $TARGET_SSH_USER@$TARGET:$TARGET_PATH
  echo "done."
  rm -rf .tmp_files
  done
