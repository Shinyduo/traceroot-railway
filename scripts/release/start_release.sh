#!/bin/bash
#
# This script:
# 1. creates a new release branch `vX.Y` from origin/main, and
# 2. generates the first tag `vX.Y.0` on the minor version `vX.Y`.
#

set -e

VERSION=$1
BASE_REF=${2:-origin/main}

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo
    echo "Usage: ./scripts/release/start_release.sh <VERSION> [BASE_REF]"
    echo
    echo "  VERSION:         The major version of the release, such as 'v1.9'"
    echo "  BASE_REF:        (optional) The git branch or commit that should"
    echo "                   be used to create the release branch. Default: origin/main"
    echo
    exit 1
fi

# Validate version format
if [[ ! "$VERSION" =~ ^v[0-9]\.[0-9]+$ ]]; then
    echo "Official release branches should have format such as v1.9 but got $VERSION"
    echo
    read -p "Do you wish to continue anyway? [Y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        false
    fi
    NOTES_ARG=""
else
    # If version is vX.0 for a new X, then we need to find the highest v(X-1).Y:
    if [[ "$VERSION" =~ ^v[0-9]+\.0$ ]]; then
        PREV_PREFIX=$(echo ${VERSION} | awk -F. '{print "v" substr($1, 2) - 1}')
        PREV_VERSION=$(git tag -l | grep -E $PREV_PREFIX | grep -E "^v[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -n 1)
    else
        PREV_VERSION=$(echo ${VERSION} | awk -F. -v OFS=. '{$NF -= 1 ; print}').0
    fi
    if [[ -n "$PREV_VERSION" ]]; then
        NOTES_ARG="--notes-start-tag ${PREV_VERSION}"
    else
        NOTES_ARG=""
    fi
fi

# Install GitHub CLI if not available
if ! command -v gh &> /dev/null; then
    if [[ $OSTYPE == "darwin"* ]]; then
        echo "Installing github cli"
        brew install gh
    elif [[ $OSTYPE == "linux-gnu" ]]; then
        type -p yum-config-manager >/dev/null || sudo yum install yum-utils
        sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo yum -y install gh
    else
        echo "Please install github CLI: https://cli.github.com/"
        false
    fi
fi

# Check GitHub CLI version
GH_VERSION=$(gh --version | perl -pe 'if(($v)=/([0-9]+([.][0-9]+)+)/){print"$v\n";exit}$_=""')
if ! { echo "2.28.0"; echo "$GH_VERSION"; } | sort -V -C; then
    gh --version
    echo "You are running an out of date version of github cli. Please upgrade to at least v2.28.0"
    false
fi

# Fetch origin/main, and confirm that this is OK
git fetch origin
git checkout $BASE_REF

git log -1
BRANCH=${VERSION}

echo
echo "We will create a new release branch '${BRANCH}' based on the above commit."
echo

read -p "Do you wish to continue? [Y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    false
fi

# Create release branch and tag
TAG=${VERSION}.0

git checkout -b $BRANCH
git push origin $BRANCH
git tag $TAG
git push origin $TAG

# Make a new release
gh release create $TAG --verify-tag --generate-notes --title $TAG $NOTES_ARG
