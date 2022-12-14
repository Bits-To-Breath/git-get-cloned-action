### CODER DO NOT CHANGE! ###
### WILL BE OVERWRITTEN! ###

REPOSITORY_TYPE_ORG="Organization"
REPOSITORY_TYPE_USER="User"

CODE_ENV="${INPUT_CODE_ENV:-dev}"
SOURCE_IS_PRIVATE="${INPUT_SOURCE_IS_PRIVATE}"
SOURCE_IS_TEMPLATE="${INPUT_SOURCE_IS_TEMPLATE}"
SOURCE_AUTH_ID="${INPUT_SOURCE_AUTH_ID}"
SOURCE_AUTH_TOKEN="${INPUT_SOURCE_AUTH_TOKEN}"
DESTINATION_AUTH_ID="${INPUT_DESTINATION_AUTH_ID}"
DESTINATION_AUTH_TOKEN="${INPUT_DESTINATION_AUTH_TOKEN}"
SOURCE_SERVICE="${INPUT_SOURCE_SERVICE}"
SOURCE_OWNER="${INPUT_SOURCE_OWNER}"
SOURCE_REPO_NAME="${INPUT_SOURCE_REPO_NAME}"
SOURCE_BRANCH="${INPUT_SOURCE_BRANCH}"
SOURCE_PATH="${INPUT_SOURCE_PATH}"
SOURCE_WIKI="${INPUT_SOURCE_WIKI}"
SOURCE_DEFAULT_BRANCH="${INPUT_SOURCE_DEFAULT_BRANCH}"
DESTINATION_IS_PRIVATE="${INPUT_DESTINATION_IS_PRIVATE}"
DESTINATION_IS_TEMPLATE="${INPUT_DESTINATION_IS_TEMPLATE}"
DESTINATION_SERVICE="${INPUT_DESTINATION_SERVICE}"
DESTINATION_OWNER="${INPUT_DESTINATION_OWNER}"
DESTINATION_REPO_NAME="${INPUT_DESTINATION_REPO_NAME}"
DESTINATION_BRANCH="${INPUT_DESTINATION_BRANCH}"
DESTINATION_PATH="${INPUT_DESTINATION_PATH}"
DESTINATION_WIKI="${INPUT_DESTINATION_WIKI}"
DESTINATION_DEFAULT_BRANCH="${INPUT_DESTINATION_DEFAULT_BRANCH}"
DESTINATION_CLEAN="${INPUT_DESTINATION_CLEAN}"
SELECT_REGEX="${INPUT_SELECT_REGEX}"
IGNORE_REGEX="${INPUT_IGNORE_REGEX}"
COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE}"
COMMIT_USERNAME="${INPUT_COMMIT_USERNAME}"
COMMIT_EMAIL="${INPUT_COMMIT_EMAIL}"

SELECT_FILES=()
MOVE_FILES=()
SOURCE_REPO=""
DESTINATION_REPO=""
SOURCE_TEMP="SOURCE_TEMP"
DESTINATION_TEMP="DESTINATION_TEMP"
PROGNAME="$(basename $0)"
ROOT_DIR="$(pwd)"
TEMP_REPOSITORY_TYPE=""

rm -rf "${SOURCE_TEMP}"
rm -rf "${DESTINATION_TEMP}"

if [ "${CODE_ENV}" = "pre-dev" ]; then
    set -Eeuxo pipefail
fi

function __error_handling__() {
    local last_status_code=$1
    local error_line_number=$2
    echo "Error - exited with status \                          
    ${last_status_code} at line ${error_line_number}"
}
trap '__error_handling__ $? $LINENO' ERR

echo "Testing Required Inputs"

if [[ -z "$SOURCE_AUTH_ID" ]]; then
    echo "SOURCE_AUTH_ID environment \
    variable is missing. Cannot proceed."
    exit 1
fi

if [[ -z "$SOURCE_AUTH_TOKEN" ]]; then
    echo "SOURCE_AUTH_TOKEN environment variable \                 
    is missing. Cannot proceed."
    exit 1
fi

if [[ -z "$DESTINATION_OWNER" ]]; then
    echo "DESTINATION_OWNER environment \                            
    variable is missing. Cannot proceed."
    exit 1
fi

if [[ -z "$DESTINATION_REPO_NAME" ]]; then
    echo "DESTINATION_REPO_NAME environment \
    variable is missing. Cannot proceed."
    exit 1
fi

echo "Testing Optional Inputs"

if [[ -z "$SOURCE_IS_PRIVATE" ]]; then
    SOURCE_IS_PRIVATE="true"
fi

if [[ -z "$SOURCE_IS_TEMPLATE" ]]; then
    SOURCE_IS_TEMPLATE="true"
fi

if [[ -z "$SOURCE_SERVICE" ]]; then
    SOURCE_SERVICE="github.com"
fi

if [[ -z "$SOURCE_OWNER" ]]; then
    SOURCE_OWNER=$GITHUB_REPOSITORY_OWNER
fi

if [[ -z "$SOURCE_REPO_NAME" ]]; then
    SOURCE_REPO_NAME=${GITHUB_REPOSITORY#*/}
fi

if [[ -z "$SOURCE_BRANCH" ]]; then
    SOURCE_BRANCH="main"
fi

if [[ -z "$SOURCE_DEFAULT_BRANCH" ]]; then
    SOURCE_DEFAULT_BRANCH="main"
fi

if [[ -z "$DESTINATION_IS_PRIVATE" ]]; then
    DESTINATION_IS_PRIVATE="true"
fi

if [[ -z "$DESTINATION_IS_TEMPLATE" ]]; then
    DESTINATION_IS_TEMPLATE="true"
fi

if [[ -z "$DESTINATION_IS_PRIVATE" ]]; then
    DESTINATION_IS_PRIVATE="true"
fi

if [[ -z "$DESTINATION_IS_TEMPLATE" ]]; then
    DESTINATION_IS_TEMPLATE="true"
fi

if [[ -z "$DESTINATION_AUTH_ID" ]]; then
    DESTINATION_AUTH_ID="$SOURCE_AUTH_ID"
fi

if [[ -z "$DESTINATION_AUTH_TOKEN" ]]; then
    DESTINATION_AUTH_TOKEN="$SOURCE_AUTH_TOKEN"
fi

if [[ -z $DESTINATION_SERVICE ]]; then
    DESTINATION_SERVICE="github.com"
fi

if [[ -z "$DESTINATION_BRANCH" ]]; then
    DESTINATION_BRANCH="main"
fi

if [[ -z "$DESTINATION_PATH" ]]; then
    DESTINATION_PATH=""
fi

if [[ -z "$DESTINATION_DEFAULT_BRANCH" ]]; then
    DESTINATION_DEFAULT_BRANCH="main"
fi

if [[ -z "$SELECT_REGEX" ]]; then
    SELECT_REGEX="(.*)"
fi

if [[ -z "$IGNORE_REGEX" ]]; then
    IGNORE_REGEX="(.*\/\.git\/.*)"
fi

if [[ -z "$COMMIT_MESSAGE" ]]; then
    COMMIT_MESSAGE="Copied repo using Git-Get-Cloned-Action\
 with epoch timestamp $(date +'%s's)"
fi

if [[ -z "$COMMIT_USERNAME" ]]; then
    COMMIT_USERNAME=$GITHUB_ACTOR
fi

if [[ -z "$COMMIT_EMAIL" ]]; then
    COMMIT_EMAIL="${COMMIT_USERNAME}@users.noreply.github.com"
fi

echo "Attempting to copy source of REPO \
https://${SOURCE_SERVICE}/${SOURCE_OWNER}\
/${SOURCE_REPO_NAME}.git to REPO \
https://${DESTINATION_SERVICE}/${DESTINATION_OWNER}\
/${SOURCE_REPO_NAME}.git"

SOURCE_REPO=${SOURCE_OWNER}/${SOURCE_REPO_NAME}
DESTINATION_REPO=${DESTINATION_OWNER}/${DESTINATION_REPO_NAME}

git config --global user.name "${COMMIT_USERNAME}"
git config --global user.email "${COMMIT_EMAIL}"

function init_repo() {
    local repo=$1
    local default_branch=$2
    local add_remote=""
    if [[ "$#" -eq 3 ]]; then
        add_remote=$3
    fi
    echo "# ${repo#*/}" > README.md
    git ini
    git add README.md
    git commit -m "first commit"
    git branch -M ${default_branch}
    if [[ -n "${add_remote}" ]]; then
        git remote add origin "${add_remote}"
    fi
    git push -u origin "${default_branch}"
}

function repo_owner_type(){
    local auth=$1
    local repo=$2
    user_type=$(curl \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${auth#*:}"\
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/users/${repo%%/*}\
        | jq --raw-output .type)
    TEMP_REPOSITORY_TYPE=${user_type}
}

function repo_exists_and_initialized() {
    local auth=$1
    local repo=$2
    local service=$3
    local temp=$4
    local branch=$5
    local default_branch=$6
    local is_private=$7
    local is_template=$8
    echo "looking for repo or creating one"
    mkdir -p "${ROOT_DIR}/${temp}"
    cd "${ROOT_DIR}"
    git ls-remote \
        "https://${auth}@${service}/${repo}.git" -q ||
    if [ "$?" -ne 0 ]; then
        echo "repo ${service}/${repo} does not exist"
        repo_owner_type "${auth}" "${repo}"
        uri_path=""
        if [ "${TEMP_REPOSITORY_TYPE}" = "User" ]; then
            uri_path="/users/${auth%%:*}/repos"
        elif [ "${TEMP_REPOSITORY_TYPE}" = "Organization" ]; then
            uri_path="/orgs/${auth%%:*}/repos"
        else
            echo "bad repository owner type ${repo_owner_type}"
            exit 1
        fi
        curl_json="{\
            \"name\":\"${repo#*/}\",\
            \"private\":${is_private},\
            \"is_template\":${is_template}\
        }"
        curl \
            -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${auth#*:}"\
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com${uri_path}" \
            -d "${curl_json}"
    fi
    git clone \
        https://${auth}@${service}/${repo}.git ${temp}
    cd "${ROOT_DIR}/${temp}"
    git log -q ||
    if [ "$?" -ne 0 ]; then
        echo "initializing repo ${repo}"
        init_repo "${repo}" "${default_branch}"
    fi
    cd "${ROOT_DIR}"
}

function repo_branch_exists() {
    local auth=$1
    local repo=$2
    local service=$3
    local temp=$4
    local branch=$5
    local default_branch=$6
    echo "checking repo ${repo} has"\
        "default branch '${default_branch}'"\
        "and new target '${branch}';"\
        "if not create"
    cd "${ROOT_DIR}/${temp}"
    git rev-parse --verify "${default_branch}"
    if [ "$?" -ne 0 ]; then
        echo "${service}/${repo} could not find default"\
            "branch ${default_branch}"\
            "creating"
        git checkout -b "${default_branch}"
        git push -u origin "${default_branch}"
    fi
    git rev-parse --verify "${branch}"
    if [ "$?" -ne 0 ]
    then
        echo "creating default branch '${branch}'"\
            "from ${default_branch}"
        git checkout ${default_branch}
        git checkout -b ${branch} ${default_branch}
        git push -u origin ${branch}
    fi
    git checkout ${branch}
    cd "${ROOT_DIR}"
}

function repo_prepare(){
    repo_exists_and_initialized "$@"
    repo_branch_exists "$@"
}

echo "checking source repo and cloning"
repo_prepare "${SOURCE_AUTH_ID}:${SOURCE_AUTH_TOKEN}"\
    "${SOURCE_OWNER}/${SOURCE_REPO_NAME}"\
    "${SOURCE_SERVICE}"\
    "${SOURCE_TEMP}"\
    "${SOURCE_BRANCH}"\
    "${SOURCE_DEFAULT_BRANCH}"\
    "${SOURCE_IS_PRIVATE}"\
    "${SOURCE_IS_TEMPLATE}"

echo "checking destination repo and cloning"
repo_prepare "${DESTINATION_AUTH_ID}:${DESTINATION_AUTH_TOKEN}"\
    "${DESTINATION_OWNER}/${DESTINATION_REPO_NAME}"\
    "${DESTINATION_SERVICE}"\
    "${DESTINATION_TEMP}"\
    "${DESTINATION_BRANCH}"\
    "${DESTINATION_DEFAULT_BRANCH}"\
    "${DESTINATION_IS_PRIVATE}"\
    "${DESTINATION_IS_TEMPLATE}"

if [ "${DESTINATION_CLEAN}" = "true" ]; then
    echo "Cleaning destination"
    cd "${ROOT_DIR}/${DESTINATION_TEMP}"
    git rm -rf .
    git clean -fxd
    cd "${ROOT_DIR}"
fi

echo "Proccesing filters using given perl regexes"
cd "${ROOT_DIR}/${SOURCE_TEMP}/${SOURCE_PATH}"
IFS=$'\n'
DIRECTORY_OBJECTS=($(find $PWD))
unset IFS

for dir_obj in "${DIRECTORY_OBJECTS[@]}"; do
    perl "${ROOT_DIR}/reg.pl" \
        "${SELECT_REGEX}" "${dir_obj}" "pre-dev"
    if [ "$?" -eq "0" ] && [ -f "${dir_obj}" ]; then
        SELECT_FILES+=("${dir_obj}")
    fi
done

for dir_obj in "${SELECT_FILES[@]}"; do
    perl "${ROOT_DIR}/reg.pl" "${IGNORE_REGEX}" "${dir_obj}" ||
    if [ "$?" -eq "1" ]; then
        MOVE_FILES+=("${dir_obj}")
    fi
done

for dir_obj in "${MOVE_FILES[@]}"; do
    local src="${ROOT_DIR}/${SOURCE_TEMP}"
    local dst="${ROOT_DIR}/${DESTINATION_TEMP}"
    dst_obj=$(echo "${dir_obj}" | sed "s#${src}#${dst}#")
    path_obj="$(dirname $dst_obj)"
    mkdir -p ${path_obj}
    cp "${dir_obj}" "${dst_obj}"
done

cd "${ROOT_DIR}/${DESTINATION_TEMP}"

echo "Copy wiki if needed"
if [ -n "${SOURCE_WIKI}" ]; then
    dst_wiki="${ROOT_DIR}/${DESTINATION_TEMP}/${DESTINATION_WIKI}"
    mkdir -p "${dst_wiki}"
    cp -R "${SOURCE_WIKI}" "${dst_wiki}"
fi

echo "Pushing changes"
git add .
git commit -m  "${COMMIT_MESSAGE}" ||
git push origin "${DESTINATION_BRANCH}"

echo "cleaning up repositories"
cd "${ROOT_DIR}"
rm -rf "${SOURCE_TEMP}"
rm -rf "${DESTINATION_TEMP}"
cd "${ROOT_DIR}"

exit 0
