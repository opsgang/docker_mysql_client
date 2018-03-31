#!/bin/bash
# vim: et sr sw=4 ts=4 smartindent:
# helper script to generate label data for docker image during building
#
# docker_build will generate an image tagged :candidate
#
# It is a post-step to tag that appropriately and push to repo

MIN_DOCKER=1.11.0
GIT_SHA_LEN=8
IMG_TAG=candidate

LIBS_VERSION=0.0.5
LIBS_URL="https://github.com/opsgang/libs/releases/download/$LIBS_VERSION/habitual.tgz"

version_gt() {
    [[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]]
}

valid_docker_version() {
    v=$(docker --version | grep -Po '\b\d+\.\d+\.\d+\b')
    if version_gt $MIN_DOCKER $v
    then
        echo "ERROR: need min docker version $MIN_DOCKER" >&2
        return 1
    fi
}

base_img(){
    grep -Po '(?<=^FROM ).*' Dockerfile
}

init_apk_versions() {
    local img="$1"
    docker pull $img >/dev/null 2>&1 || return 1
}

apk_pkg_version() {
    local img="$1"
    local pkg="$2"

    docker run -i --rm $img apk --no-cache --update info $pkg \
    | grep -Po "(?<=^$pkg-)[^ ]+(?= description:)" | head -n 1
}

built_by() {
    local user="--UNKNOWN--"
    if [[ ! -z "${BUILD_URL}" ]]; then
        user="${BUILD_URL}"
    elif [[ ! -z "${AWS_PROFILE}" ]] || [[ ! -z "${AWS_ACCESS_KEY_ID}" ]]; then
        user="$(aws iam get-user --query 'User.UserName' --output text)@$HOSTNAME"
    else
        user="$(git config --get user.name)@$HOSTNAME"
    fi
    echo "$user"
}

git_uri(){
    git config remote.origin.url || echo 'no-remote'
}

git_sha(){
    git rev-parse --short=${GIT_SHA_LEN} --verify HEAD
}

git_branch(){
    r=$(git rev-parse --abbrev-ref HEAD)
    [[ -z "$r" ]] && echo "ERROR: no rev to parse when finding branch? " >&2 && return 1
    [[ "$r" == "HEAD" ]] && r="from-a-tag"
    echo "$r"
}

img_name(){
    (
        set -o pipefail;
        grep -Po '(?<=[nN]ame=")[^"]+' Dockerfile | head -n 1
    )
}

labels() {
	bi=$(base_img) || return 1
	init_apk_versions $bi || return 1

	myv=$(apk_pkg_version "$bi" "mysql-client")
    gu=$(git_uri) || return 1
    gs=$(git_sha) || return 1
    gb=$(git_branch) || return 1
    gt=$(git describe 2>/dev/null || echo "no-git-tag")
    bb=$(built_by) || return 1

    bb=$(echo $bb | sed -e 's/[" ]+/__/g')

    cat<<EOM
    --label version=$(date +'%Y%m%d%H%M%S')
    --label opsgang.mysql_client_version=$myv
    --label opsgang.libs_version=$LIBS_VERSION
    --label opsgang.build_git_uri=$gu
    --label opsgang.build_git_sha=$gs
    --label opsgang.build_git_branch=$gb
    --label opsgang.build_git_tag=$gt
    --label opsgang.built_by=$bb
EOM
}

get_libs() {
    local url="$1"
    local dest="$2"
    (
        set -o pipefail
        curl -sS -L -H 'Accept: application/octet-stream' "$url" \
        | tar -xzv -C $dest
    )
}

docker_build(){

    valid_docker_version || return 1

    # ... fetch opsgang/libs
    get_libs "$LIBS_URL" "./assets" || return 1

    labels=$(labels) || return 1
    n=$(img_name) || return 1

    echo "INFO: adding these labels:"
    echo "$labels"
    echo "INFO: building $n:$IMG_TAG"

    docker build --no-cache=true --force-rm $labels -t $n:$IMG_TAG .
}

docker_build
