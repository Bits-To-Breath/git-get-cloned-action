#!/bin/bash
#
# @author Austin Hogan <bitstobreath@users.noreply.github.com>
# @date 2022-12-14
# @license MIT
# @version 0.1.0

## Note
# This file is very talkative and verbose.
# Please run `clean_code.sh` and view 
# `reference_only_entrypoint.clean.sh`
# This will have the code only, in case you prefer that

## Constants
REPOSITORY_TYPE_ORG="Organization"
REPOSITORY_TYPE_USER="User"

## Global Variable Assignment
# From External Input (GitHub Action env vars)
# Tutorial on perl PCRE2 regex expression
# for new users of perl PCRE2 regex
# Go to https://regex101.com/ and select PCRE2
CODE_ENV="${INPUT_CODE_ENV:-dev}"                                   # optional: code environment to use, defaults to `dev`
SOURCE_IS_PRIVATE="${INPUT_SOURCE_IS_PRIVATE}"                      # optional: source repository is private. defaults to true
SOURCE_IS_TEMPLATE="${INPUT_SOURCE_IS_TEMPLATE}"                    # optional: source repository is template. defaults to false
SOURCE_AUTH_ID="${INPUT_SOURCE_AUTH_ID}"                            # required: usually github username
SOURCE_AUTH_TOKEN="${INPUT_SOURCE_AUTH_TOKEN}"                      # required: generated, usually personal access token
DESTINATION_AUTH_ID="${INPUT_DESTINATION_AUTH_ID}"                  # required: usually github username
DESTINATION_AUTH_TOKEN="${INPUT_DESTINATION_AUTH_TOKEN}"            # required: generated, usually personal access token
SOURCE_SERVICE="${INPUT_SOURCE_SERVICE}"                            # optional: github compatible service, default to github.com
SOURCE_OWNER="${INPUT_SOURCE_OWNER}"                                # optional: org or user name, defaults to current repository
SOURCE_REPO_NAME="${INPUT_SOURCE_REPO_NAME}"                        # optional: name of repository, defaults to current repository
SOURCE_BRANCH="${INPUT_SOURCE_BRANCH}"                              # optional: branch name, default to main
SOURCE_PATH="${INPUT_SOURCE_PATH}"                                  # optional: source path, default is root folder
SOURCE_WIKI="${INPUT_SOURCE_WIKI}"                                  # optional: source wiki, default to empty. ex: .wiki
SOURCE_DEFAULT_BRANCH="${INPUT_SOURCE_DEFAULT_BRANCH}"              # optional: source deafult branch when creating new, default to main. ex: prod
DESTINATION_IS_PRIVATE="${INPUT_DESTINATION_IS_PRIVATE}"            # optional: destination repository is private. defaults to true
DESTINATION_IS_TEMPLATE="${INPUT_DESTINATION_IS_TEMPLATE}"          # optional: destination repository is template. defaults to false
DESTINATION_SERVICE="${INPUT_DESTINATION_SERVICE}"                  # optional: github compatible service, default to github.com
DESTINATION_OWNER="${INPUT_DESTINATION_OWNER}"                      # required: org or user name 
DESTINATION_REPO_NAME="${INPUT_DESTINATION_REPO_NAME}"              # required: name of repository
DESTINATION_BRANCH="${INPUT_DESTINATION_BRANCH}"                    # optional: branch name, default to main
DESTINATION_PATH="${INPUT_DESTINATION_PATH}"                        # optional: destination path, default is root folder
DESTINATION_WIKI="${INPUT_DESTINATION_WIKI}"                        # optional: destination wiki, default to empty. ex: .wiki
DESTINATION_DEFAULT_BRANCH="${INPUT_DESTINATION_DEFAULT_BRANCH}"    # optional: destination deafult branch when creating new, default to main. ex: prod
DESTINATION_CLEAN="${INPUT_DESTINATION_CLEAN}"                      # optional: destination clean, defaults to string false
SELECT_REGEX="${INPUT_SELECT_REGEX}"                                # optional: select regex will find and add any matching file/folder paths as long as they do not match the ignore regex
IGNORE_REGEX="${INPUT_IGNORE_REGEX}"                                # optional: ignore regex will remove any file/folder paths that match. ex: (.+\/.git\/*) ignores the git directory
COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE}"                            # optional: commit message
COMMIT_USERNAME="${INPUT_COMMIT_USERNAME}"                          # optional: commit username, defaults to GITHUB_ACTOR
COMMIT_EMAIL="${INPUT_COMMIT_EMAIL}"                                # optional: commit email, defaults to GITHUB_ACTOR@users.noreply.github.com

# Global Variables for use within the script
SELECT_FILES=()                                                     # define array to store selected files
MOVE_FILES=()                                                       # define array of files to move
SOURCE_REPO=""                                                      # define string to store source repo fule name `owner/path`
DESTINATION_REPO=""                                                 # define string to store destination repo full name `owner/path`
SOURCE_TEMP="SOURCE_TEMP"                                           # define source temporary directory to store git repo
DESTINATION_TEMP="DESTINATION_TEMP"                                 # define destination temporary directory to store git repo
PROGNAME="$(basename $0)"                                           # define program name variable
ROOT_DIR="$(pwd)"                                                   # define root directory variable
TEMP_REPOSITORY_TYPE=""                                             # define temporary variable for repository type {organization, user}
RC=-1                                                               # define return code or RC of the previous command

## Cleanup for Local Testing
if [ -d "${SOURCE_TEMP}" ] || [ -d "${DESTINATION_TEMP}" ]      # check if source or destination temporary folder exists from last run
then                                                            # if true then {}
    rm -rf "${SOURCE_TEMP}"                                     # remove source temp repository
    rm -rf "${DESTINATION_TEMP}"                                # remove destination temp repository
fi                                                              # (end if)

## Make temporary directories
echo "making temporary folders"                                 # echo context
mkdir -p "${SOURCE_TEMP}"                                       # make source temporary directory
mkdir -p "${DESTINATION_TEMP}"                                  # make destination temporary directory

## Copy Perl regex script to working directory
if [[ -f /reg.pl ]]; then                                       # check file exists at top directory
    echo "copying reg.pl to ${ROOT_DIR}"                        # echo context, copying reg.pl to working directory
    cp /reg.pl "${ROOT_DIR}"                                    # run simple copy
fi                                                              # (end if)

## Error Management
if [ "${CODE_ENV}" = "pre-dev" ]; then                          # check is pre-development environment (local)
    set -Eeuxo pipefail                                         # trace-error, exit immediately, print trace, exit unset vars, print command trace
fi                                                              # (end if)

## Set Trap for Custom Error Management if needed
# function for trapping and handling any errors or custom
# error situations
function __error_handling__() {                                 # error handling function declaration
    local last_status_code=$1                                   # local variable last status code
    local error_line_number=$2                                  # local variable error line number (in this script)
    echo "Error - exited with status \                          
    ${last_status_code} at line ${error_line_number}"           # echo information about error code
}                                                               # (end function declaration)
# trap for connecting error handler function with error codes
# and line numbers for any error
trap '__error_handling__ $? $LINENO' ERR                        # trap call to error handling function with inputs for any error (ERR)

# Details:::
#
# -E :: error trace
#
# -e ::
# Exit immediately if a simple command exits with a non-zero
# status, unless the command that fails is part of an until 
# or  while loop, part of an if statement, part of a && or 
# || list, or if the command's return status is being inverted 
# using !.
#
# -u ::
# Treat unset variables and parameters other than the special
# parameters ‘@’ or ‘*’, or array variables subscripted with
# ‘@’ or ‘*’, as an error when performing parameter expansion.
# An error message will be written to the standard error, and
# a non-interactive shell will exit.s
#
# -x ::
# Print a trace of simple commands and their arguments
# after they are expanded and before they are executed.
#
# -o pipefail ::
# If set, the return value of a pipeline is the value of the
# last (rightmost) command to exit with a non-zero status, or
# zero if all commands in the pipeline exit successfully. By
# default, pipelines only return a failure if the last
# command errors.

## Required Inputs Section
# If they are not populated, exit if so

# Message to console
echo "Testing Required Inputs"                                      # echo section

# Check Auth User/Type
if [[ -z "$SOURCE_AUTH_ID" ]]; then                                 # empty authentication user name (octocat) or type (oauth2)
    echo "SOURCE_AUTH_ID environment \
    variable is missing. Cannot proceed."                           # required variable warning
    exit 1                                                          # exit script
fi                                                                  # (end if)

# Check Auth Token
if [[ -z "$SOURCE_AUTH_TOKEN" ]]; then                              # empty authentication token
    echo "SOURCE_AUTH_TOKEN environment variable \                 
    is missing. Cannot proceed."                                    # required variable warning
    exit 1                                                          # exit script
fi                                                                  # (end if)

# Check Destination Owner
if [[ -z "$DESTINATION_OWNER" ]]; then                              # empty destination owner
    echo "DESTINATION_OWNER environment \                            
    variable is missing. Cannot proceed."                           # required variable warning
    exit 1                                                          # exit script
fi                                                                  # (end if)

# Check Destination Repo Name
if [[ -z "$DESTINATION_REPO_NAME" ]]; then                          # empty destination repo name
    echo "DESTINATION_REPO_NAME environment \
    variable is missing. Cannot proceed."                           # required variable warning
    exit 1                                                          # exit script
fi                                                                  # (end if)

## Optional inputs
echo "Testing Optional Inputs"                                      # echo section

# Check source is private
if [[ -z "$SOURCE_IS_PRIVATE" ]]; then                              # empty source is private
    SOURCE_IS_PRIVATE="true"                                        # set default string
fi                                                                  # (end if)

# Check source is template
if [[ -z "$SOURCE_IS_TEMPLATE" ]]; then                             # empty source is template
    SOURCE_IS_TEMPLATE="true"                                       # set default string
fi                                                                  # (end if)

# Check Source Service
if [[ -z "$SOURCE_SERVICE" ]]; then                                 # empty source service
    SOURCE_SERVICE="github.com"                                     # set default string
fi                                                                  # (end if)

# Check Source Owner
if [[ -z "$SOURCE_OWNER" ]]; then                                   # empty source owner
    SOURCE_OWNER=$GITHUB_REPOSITORY_OWNER                           # set default string
fi                                                                  # (end if)

# Check Source Repo Name
if [[ -z "$SOURCE_REPO_NAME" ]]; then                               # empty source repo name
    SOURCE_REPO_NAME=${GITHUB_REPOSITORY#*/}                        # set default string
fi                                                                  # (end if)

# Check Source Repo Branch
if [[ -z "$SOURCE_BRANCH" ]]; then                                  # empty source branch
    SOURCE_BRANCH="main"                                            # set default string
fi                                                                  # (end if)

# Check Source default branch
if [[ -z "$SOURCE_DEFAULT_BRANCH" ]]; then                          # empty source deafult branch
    SOURCE_DEFAULT_BRANCH="main"                                    # set default string
fi                                                                  # (end if)

# Check destination is private
if [[ -z "$DESTINATION_IS_PRIVATE" ]]; then                         # empty destination is private
    DESTINATION_IS_PRIVATE="true"                                   # set default string
fi                                                                  # (end if)

# Check destination is template
if [[ -z "$DESTINATION_IS_TEMPLATE" ]]; then                        # empty destination is template
    DESTINATION_IS_TEMPLATE="true"                                  # set default string
fi                                                                  # (end if)


# Check destination is private
if [[ -z "$DESTINATION_IS_PRIVATE" ]]; then                         # empty destination is private
    DESTINATION_IS_PRIVATE="true"                                   # set default string
fi                                                                  # (end if)

# Check destination is template
if [[ -z "$DESTINATION_IS_TEMPLATE" ]]; then                        # empty destination is template
    DESTINATION_IS_TEMPLATE="true"                                  # set default string
fi                                                                  # (end if)

# Check Destination Auth ID
if [[ -z "$DESTINATION_AUTH_ID" ]]; then                            # empty authentication id
    DESTINATION_AUTH_ID="$SOURCE_AUTH_ID"                           # set default string
fi                                                                  # (end if)

# Check Destination Auth Token
if [[ -z "$DESTINATION_AUTH_TOKEN" ]]; then                         # empty authentication token
    DESTINATION_AUTH_TOKEN="$SOURCE_AUTH_TOKEN"                     # set default string
fi                                                                  # (end if)

# Check Destination Service
if [[ -z $DESTINATION_SERVICE ]]; then                              # empty destination service
    DESTINATION_SERVICE="github.com"                                # set default string
fi                                                                  # (end if)

# Check Destination Repo Branch
if [[ -z "$DESTINATION_BRANCH" ]]; then                             # empty destination branch
    DESTINATION_BRANCH="main"                                       # set default string
fi                                                                  # (end if)

# Check Destination Path
if [[ -z "$DESTINATION_PATH" ]]; then                               # empty destination path
    DESTINATION_PATH=""                                             # set default string
fi                                                                  # (end if)

# Check Destination default branch
if [[ -z "$DESTINATION_DEFAULT_BRANCH" ]]; then                     # empty destination deafult branch
    DESTINATION_DEFAULT_BRANCH="main"                               # set default string
fi                                                                  # (end if)

# Check if Select Regex is empty, default to select all if so
if [[ -z "$SELECT_REGEX" ]]; then                                   # empty select regex
    SELECT_REGEX="(.*)"                                             # set default regex (select all)
fi                                                                  # (end if)

# Check if Ignore Regex is empty, default to select none if so
if [[ -z "$IGNORE_REGEX" ]]; then                                   # empty ignore regex
    IGNORE_REGEX="(.*\/\.git\/.*)"                                      # set default regex (ignore none)
fi                                                                  # (end if)

# Check commit message is empty, default to simple message
if [[ -z "$COMMIT_MESSAGE" ]]; then                                 # empty commit message
    COMMIT_MESSAGE="Copied repo using Git-Get-Cloned-Action\
 with epoch timestamp $(date +'%s's)"                               # set default string
fi                                                                  # (end if)

# Check commit username
if [[ -z "$COMMIT_USERNAME" ]]; then                                # empty commit username
    COMMIT_USERNAME=$GITHUB_ACTOR                                   # set default string
fi                                                                  # (end if)

# Check commit email
if [[ -z "$COMMIT_EMAIL" ]]; then                                   # empty commit email
    COMMIT_EMAIL="${COMMIT_USERNAME}@users.noreply.github.com"      # set default string
fi                                                                  # (end if)

# Message to console
echo "Attempting to copy source of REPO \
https://${SOURCE_SERVICE}/${SOURCE_OWNER}\
/${SOURCE_REPO_NAME}.git to REPO \
https://${DESTINATION_SERVICE}/${DESTINATION_OWNER}\
/${DESTINATION_REPO_NAME}.git"                                      # echo context of copy procedure

## Assign globals
SOURCE_REPO=${SOURCE_OWNER}/${SOURCE_REPO_NAME}                     # set repository path for source
DESTINATION_REPO=${DESTINATION_OWNER}/${DESTINATION_REPO_NAME}      # set repository path for desination

## Assign git values
git config --global user.name "${COMMIT_USERNAME}"                  # set git config global username
git config --global user.email "${COMMIT_EMAIL}"                    # set git config global email

## Custom Functions

# function to init repo
function init_repo() {                                              # declare init_repo function
    local repo=$1                                                   # assign input 1 locally as repository: used to define the repository name for the README.md
    local default_branch=$2                                         # assign input 2 locally as default branch: string, often `main`
    local add_remote=""                                             # temporary assignment    
    if [[ "$#" -eq 3 ]]; then                                       # check if input 3 is not empty 
        add_remote=$3                                               # assign input 3 locally as add remote: full https address
    fi                                                              # (end if)
    echo "# ${repo#*/}" > README.md                                 # initialize README.md with repo name as title
    git init                                                        # initialize git repository
    git add README.md                                               # add README.md
    git commit -m "first commit"                                    # make first commit
    git branch -M ${default_branch}                                 # create first branch
    if [[ -n "${add_remote}" ]]; then                               # if new repository add remote will not be empty
        git remote add origin "${add_remote}"                       # apply remote origin address
    fi                                                              # (end if)
    git push -u origin "${default_branch}"                          # push changes from default branch to remote origin
}                                                                   # (end function declaration)

# function to check if repository is organization or user
function repo_owner_type(){                                         # declare repo_owner_type function, takes care of checking api for repo type
    local auth=$1                                                   # local auth variable assignment
    local repo=$2                                                   # local repo variable assignment
    user_type=$(curl \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${auth#*:}"\
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/users/${repo%%/*}\
        | jq --raw-output .type)                                    # set user_type
    TEMP_REPOSITORY_TYPE=${user_type}                               # assign gloabl temporary repository type
}

# function to check if repository exists, create one if not
# else
# check if repository is clonable and initialized
function repo_exists_and_initialized() {                            # declare repo_exists_and_initialized function, takes care of empty or non-existant repository
    local auth=$1                                                   # auth string `auth_id:auth_token`
    local repo=$2                                                   # repository path for address
    local service=$3                                                # repository service for address
    local temp=$4                                                   # repository temporary directory path
    local branch=$5                                                 # repository branch
    local default_branch=$6                                         # repository default branch
    local is_private=$7                                             # repository is private
    local is_template=$8                                            # repository is template
    echo "looking for repo or creating one, ${repo}"                # echo context
    mkdir -p "${ROOT_DIR}/${temp}"                                  # make full path of directory at root using the temporary repository directory name
    cd "${ROOT_DIR}"                                                # change directory to root and temporary repository directory name
    git ls-remote \
        "https://${auth}@${service}/${repo}.git" -q || RC=$?        # list/check remote repository and ignore trap
    if [ "$RC" -ne 0 ]; then                                        # repository does not exist?
        echo "repo ${repo} does not exist"                          # echo context
        repo_owner_type "${auth}" "${repo}"                         # assign repo_owner_type
        uri_path=""                                                 # assign uri path to empty string
        if [ "${TEMP_REPOSITORY_TYPE}" = "User" ]; then             # is User type owner
            uri_path="/users/${auth%%:*}/repos"                     # assign User type uri
        elif [ "${TEMP_REPOSITORY_TYPE}" = "Organization" ]; then   # is Organization type repository
            uri_path="/orgs/${auth%%:*}/repos"                      # assign Organization type uri
        else                                                        # otherwise failure
            echo "bad repository owner type ${repo_owner_type}"     # echo error information
            exit 1                                                  # exit failure
        fi                                                          # (end if)
        curl_json="{\
            \"name\":\"${repo#*/}\",\
            \"private\":${is_private},\
            \"is_template\":${is_template}\
        }"                                                          # json information for curl call to create repo
        curl \
            -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${auth#*:}"\
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com${uri_path}" \
            -d "${curl_json}"                                       # POST curl request to create repo
    fi                                                              # (end if)
    git clone \
        https://${auth}@${service}/${repo}.git ${temp}              # git clone repository into repository temporary directory
    cd "${ROOT_DIR}/${temp}"                                        # change directory to root and temporary repository directory name
    git log -q ||                                                   # check for commit log, fails if no commits exist and ignore trap
    if [ "$?" -ne 0 ]; then                                         # if previous cmd is not successful initialize repository
        echo "initializing repo ${repo}"                            # echo context
        init_repo "${repo}" "${default_branch}"                     # call init_repo with only two inputs as repository is created but not initialized
    fi                                                              # (end if)
    cd "${ROOT_DIR}"                                                # change directory back to root
}                                                                   # (continue function call)

# function to check if repository branch exists, if not create branch, finally checkout branch
function repo_branch_exists() {                                     # declare repo_branch_exists function, check for repository branch existing, create a branch if the branch does not exist
    local auth=$1                                                   # auth string `auth_id:auth_token`
    local repo=$2                                                   # repository path for address
    local service=$3                                                # repository service for address
    local temp=$4                                                   # repository temporary directory path
    local branch=$5                                                 # repository branch
    local default_branch=$6                                         # repository default branch
    echo "checking repo ${repo} has"\
        "default branch '${default_branch}'"\
        "and target branch '${branch}';"\
        "if not create"                                             # echo context
    cd "${ROOT_DIR}/${temp}"                                        # change directory to root and temporary repository directory name
    git rev-parse --verify "${default_branch}"                      # verify branch exists
    if [ "$?" -ne 0 ]; then                                         # if default branch does not exist
        echo "${service}/${repo} could not find default"\
            "branch ${default_branch}"\
            "creating"                                              # echo context
        git checkout -b "${default_branch}"                         # checkout git branch
        git push -u origin "${default_branch}"                      # push defaul branch
    fi                                                              # (end if)
    git rev-parse --verify "origin/${branch}" || RC=$?              # verify branch exists
    if [ "$RC" -ne 0 ]                                               # target branch DNE
    then                                                            # if true
        echo "creating default branch '${branch}'"\
            "from ${default_branch}"                                # echo context
        git checkout ${default_branch}                              # checkout default branch
        git checkout -b ${branch} ${default_branch}                 # create branch from default branch
        git push -u origin ${branch}                                # push branch
    fi                                                              # (end if)
    git checkout ${branch}                                          # checkout target branch
    cd "${ROOT_DIR}"                                                # change directory to root directory
}                                                                   # (end function declaration)

function repo_prepare(){                                            # declare repo_prepare function, pushes input to two similar functions
    repo_exists_and_initialized "$@"                                # call repo_exists_and_initialize with inputs
    repo_branch_exists "$@"                                         # call repo_branch_exists with inputs
}                                                                   # (end function declaration)

## Call required functions to prepare source and destination repositories
echo "checking source repo and cloning"                             # echo context
repo_prepare "${SOURCE_AUTH_ID}:${SOURCE_AUTH_TOKEN}"\
    "${SOURCE_OWNER}/${SOURCE_REPO_NAME}"\
    "${SOURCE_SERVICE}"\
    "${SOURCE_TEMP}"\
    "${SOURCE_BRANCH}"\
    "${SOURCE_DEFAULT_BRANCH}"\
    "${SOURCE_IS_PRIVATE}"\
    "${SOURCE_IS_TEMPLATE}"                                         # prepare source repository

echo "checking destination repo and cloning"                        # echo context
repo_prepare "${DESTINATION_AUTH_ID}:${DESTINATION_AUTH_TOKEN}"\
    "${DESTINATION_OWNER}/${DESTINATION_REPO_NAME}"\
    "${DESTINATION_SERVICE}"\
    "${DESTINATION_TEMP}"\
    "${DESTINATION_BRANCH}"\
    "${DESTINATION_DEFAULT_BRANCH}"\
    "${DESTINATION_IS_PRIVATE}"\
    "${DESTINATION_IS_TEMPLATE}"                                    # prepare destination repository

## Clean destination if needed
if [ "${DESTINATION_CLEAN}" = "true" ]; then                        # Clean destination
    echo "Cleaning destination"                                     # echo context
    cd "${ROOT_DIR}/${DESTINATION_TEMP}"                            # change to destination directory
    git rm -rf .                                                    # git remove all files and folders except .git
    git clean -fxd                                                  # clean untracked files, remove ignored files, remove directories
    cd "${ROOT_DIR}"                                                # change to root directory
fi                                                                  # (end if)

## Filter and process folders and files to be cloned
echo "Proccesing filters using given perl regexes"                  # echo context
cd "${ROOT_DIR}/${SOURCE_TEMP}/${SOURCE_PATH}"                      # enter source directory
IFS=$'\n'                                                           # temporarily set IFS
DIRECTORY_OBJECTS=($(find $PWD))                                    # find local files for processing
unset IFS                                                           # unset IFS

for dir_obj in "${DIRECTORY_OBJECTS[@]}"; do                        # begin for loop
    perl "${ROOT_DIR}/reg.pl" \
        "${SELECT_REGEX}" "${dir_obj}" "pre-dev" ||  RC=$?          # get regex result
    if [ "$RC" -eq "0" ] && [ -f "${dir_obj}" ]; then               # compare regex result and check if it is a file to move
        SELECT_FILES+=("${dir_obj}")                                # append directory object to
    fi                                                              # (end if)
done                                                                # (done loop)

for dir_obj in "${SELECT_FILES[@]}"; do                             # begin for loop
    perl "${ROOT_DIR}/reg.pl" \
        "${IGNORE_REGEX}" "${dir_obj}" || RC=$?                     # get regex result
    if [ "$RC" -eq "1" ]; then                                      # compare regex result and check if it is a file to move
        MOVE_FILES+=("${dir_obj}")                                  # append directory object to 
    fi                                                              # (end if)
done                                                                # (done loop)

for dir_obj in "${MOVE_FILES[@]}"; do                               # begin for loop
    src="${ROOT_DIR}/${SOURCE_TEMP}"                                # source path
    dst="${ROOT_DIR}/${DESTINATION_TEMP}"                           # destination path
    dst_obj=$(echo "${dir_obj}" | sed "s#${src}#${dst}#")           # assign destination object
    path_obj="$(dirname $dst_obj)"                                  # assign path object from file path
    mkdir -p ${path_obj}                                            # make directory inside object destination
    cp "${dir_obj}" "${dst_obj}"                                    # copy source files to destination files
done                                                                # (done loop)

cd "${ROOT_DIR}/${DESTINATION_TEMP}"                                # change to destination folder

## Copy wikis
if [ -n "${SOURCE_WIKI}" ]; then                                    # if source wiki exists
    echo "Copying the wiki"                                         # copy the wiki if needed
    src_wiki="${ROOT_DIR}/${SOURCE_TEMP}/${SOURCE_WIKI}"            # destination wiki
    dst_wiki="${ROOT_DIR}/${DESTINATION_TEMP}/${DESTINATION_WIKI}"  # destination wiki
    mkdir -p "${dst_wiki}"                                          # make path to destination wiki
    cp -R "${src_wiki}" "${dst_wiki}"                               # cp recursively source wiki
fi                                                                  # (end if)

## Push changes
echo "Pushing changes"                                              # echo context
git add .                                                           # git add all changes
git commit -m  "${COMMIT_MESSAGE}" ||                               # git commit message
git push origin "${DESTINATION_BRANCH}"                             # git push origin to destination branch

## Cleanup
echo "cleaning up repositories"                                     # echo context
cd "${ROOT_DIR}"                                                    # enter root directory
# rm -rf "${SOURCE_TEMP}"                                             # remove source temp repository
# rm -rf "${DESTINATION_TEMP}"                                        # remove destination temp repository
cd "${ROOT_DIR}"                                                    # change to root directory

exit 0                                                              # end program success
