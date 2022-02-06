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

if [[ $GITHUB_REF =~ ${INPUT_BRANCH}$ ]]; then
    export ENV_NAME=$INPUT_ENVIROMENT; 
else 
    echo "FAILURE: Branch name required." && exit 1;
fi

echo "Deploying $GITHUB_REF to $ENV_NAME..."

#Deploy Vars
SSH_HOST=$INPUT_SSH_HOST
REMOTE_DIR_PATH=$INPUT_SSH_REMOTE_PATH
SRC_PATH=$INPUT_LOCAL_SRC_PATH


 
# Set up our user and path

SSH_USER="$INPUT_SSH_USER"@"$SSH_HOST"
DESTINATION=$SSH_USER":"$REMOTE_DIR_PATH

# Setup our SSH Connection & use keys
mkdir "$SSH_PATH"
ssh-keyscan -t rsa "$SSH_HOST" >> "$KNOWN_HOSTS_PATH"

#Copy Secret Keys to container
echo "$INPUT_SSHG_KEY_PRIVATE" > "$SSHG_KEY_PRIVATE_PATH"
#Set Key Perms 
chmod 700 "$SSH_PATH"
chmod 644 "$KNOWN_HOSTS_PATH"
chmod 600 "$SSHG_KEY_PRIVATE_PATH"

# Deploy via SSH
# Exclude restricted paths from exclude.txt
rsync --rsh="ssh -v -p $INPUT_SSH_PORT -i ${SSHG_KEY_PRIVATE_PATH} -o StrictHostKeyChecking=no" $INPUT_FLAGS --exclude-from='/exclude.txt' $SRC_PATH "$DESTINATION"