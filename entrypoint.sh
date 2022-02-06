#!/bin/bash -l

set -e

: ${INPUT_SSHG_KEY_PRIVATE?Required secret not set.}

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
elif [[ $GITHUB_REF =~ ${INPUT_STG_BRANCH}$ ]]; then
    export WPE_ENV_NAME=$INPUT_STG_ENV;
elif [[ $GITHUB_REF =~ ${INPUT_DEV_BRANCH}$ ]]; then
    export WPE_ENV_NAME=$INPUT_DEV_ENV;    
else 
    echo "FAILURE: Branch name required." && exit 1;
fi

echo "Deploying $GITHUB_REF to $WPE_ENV_NAME..."

#Deploy Vars
WPE_SSH_HOST="162.241.194.20"
DIR_PATH="deploy-test"
SRC_PATH="."
 
# Set up our user and path

WPE_SSH_USER="olehrusyi"@"$WPE_SSH_HOST"
WPE_DESTINATION=$WPE_SSH_USER":"$DIR_PATH

# Setup our SSH Connection & use keys
mkdir "$SSH_PATH"
ssh-keyscan -t rsa "$WPE_SSH_HOST" >> "$KNOWN_HOSTS_PATH"

#Copy Secret Keys to container
echo "$INPUT_SSHG_KEY_PRIVATE" > "$SSHG_KEY_PRIVATE_PATH"
#Set Key Perms 
chmod 700 "$SSH_PATH"
chmod 644 "$KNOWN_HOSTS_PATH"
chmod 600 "$SSHG_KEY_PRIVATE_PATH"

# Deploy via SSH
# Exclude restricted paths from exclude.txt
rsync --rsh="ssh -v -p 2222 -i ${SSHG_KEY_PRIVATE_PATH} -o StrictHostKeyChecking=no" $INPUT_FLAGS --exclude-from='/exclude.txt' $SRC_PATH "$WPE_DESTINATION"