#!/bin/bash -l

set -e

: ${INPUT_SSH_KEY_PRIVATE?Required secret not set.}

#SSH Key Vars 
SSH_PATH="$HOME/.ssh"
KNOWN_HOSTS_PATH="$SSH_PATH/known_hosts"
SSHG_KEY_PRIVATE_PATH="$SSH_PATH/github_action"


###
# If you'd like to expand the environments, 
# Just copy/paste an elif line and the following export
# Then adjust variables to match the new ones you added in main.yml
#
# Example:
#
# elif [[ ${GITHUB_REP} =~ ${INPUT_NEW_BRANCH_NAME}$ ]]; then
#     export WPE_ENV_NAME=${INPUT_NEW_ENV_NAME};    
###

if [[ $GITHUB_REF =~ ${INPUT_PRD_BRANCH}$ ]]; then
    export WPE_ENV_NAME=$INPUT_PRD_ENV;
else 
    echo "FAILURE: Branch name required." && exit 1;
fi

echo "Deploying $GITHUB_REF to $WPE_ENV_NAME..."

#Deploy Vars
REMOTE_SSH_HOST=$INPUT_SSH_REMOTE_HOST
REMOTE_SSH_PORT=$INPUT_SSH_REMOTE_PORT
DIR_PATH=$INPUT_DIST_DIR
SRC_PATH=$INPUT_LOCAL_DIR

echo "Vars - ok"
 
# Set up our user and path

REMOTE_SSH_USER="$INPUT_SSH_REMOTE_USER"@"$REMOTE_SSH_HOST"
WPE_DESTINATION=$REMOTE_SSH_USER":"$DIR_PATH

echo "User - ok"

# Setup our SSH Connection & use keys
mkdir "$SSH_PATH"

echo "Dir - ok"

ssh-keyscan -t rsa -p "$REMOTE_SSH_PORT" "$REMOTE_SSH_HOST" >> "$KNOWN_HOSTS_PATH"

echo "Scan - ok"

#Copy Secret Keys to container
echo "$INPUT_SSH_KEY_PRIVATE" > "$SSHG_KEY_PRIVATE_PATH"
#Set Key Perms 
chmod 700 "$SSH_PATH"
chmod 644 "$KNOWN_HOSTS_PATH"
chmod 600 "$SSHG_KEY_PRIVATE_PATH"

echo "Key - ok"

# Deploy via SSH
# Exclude restricted paths from exclude.txt
rsync --delete --rsh="ssh -v -p $REMOTE_SSH_PORT -i ${SSHG_KEY_PRIVATE_PATH} -o StrictHostKeyChecking=no" $INPUT_FLAGS --exclude-from='/exclude.txt' $SRC_PATH "$WPE_DESTINATION"