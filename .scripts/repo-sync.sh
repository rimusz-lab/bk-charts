#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

 # USAGE: repo-sync.sh <commit-changes?>

 log() {
   # shellcheck disable=SC1117
   echo -e "\033[0;33m$(date "+%H:%M:%S")\033[0;37m ==> $1."
 }

 install_helm_cli() {
   mkdir tmp
   curl -k -L https://storage.googleapis.com/kubernetes-helm/helm-"${HELM_VERSION}"-linux-amd64.tar.gz > tmp/helm.tar.gz
   tar xvf tmp/helm.tar.gz -C tmp --strip=1 linux-amd64/helm > /dev/null 2>&1
   chmod +x tmp/helm
   sudo mv tmp/helm /usr/local/bin/
   helm init --client-only
 }

 travis_setup_git() {
   git config user.email "travis@travis-ci.org"
   git config user.name "Travis CI"
   COMMIT_MSG="Updating chart repository, travis build #$TRAVIS_BUILD_NUMBER"
   # git remote add upstream "https://$GH_TOKEN@github.com/buildkite/charts.git"
   git remote add upstream "https://$GH_TOKEN@github.com/rimusz-lab/bk-charts.git"
 }

 show_important_vars() {
     echo "  REPO_URL: $REPO_URL"
     echo "  BUILD_DIR: $BUILD_DIR"
     echo "  REPO_DIR: $REPO_DIR"
     echo "  TRAVIS: $TRAVIS"
     echo "  COMMIT_CHANGES: $COMMIT_CHANGES"
 }

 COMMIT_CHANGES="${1}"
 : "${COMMIT_CHANGES:=false}"
 : "${TRAVIS:=false}"
 #REPO_URL=https://buildkite.github.io/charts
 REPO_URL=https://rimusz-lab.github.io/bk-charts/
 BUILD_DIR=$(mktemp -d)
 # Root directory
 ## REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
 REPO_DIR="$( pwd )"
 COMMIT_MSG="Updating chart repository"

 show_important_vars
 install_helm_cli
 
 if [ $TRAVIS != "false" ]; then
   log "Configuring git for Travis-ci"
   travis_setup_git
 else
   # git remote add upstream git@github.com:buildkite/charts.git || true
   git remote add upstream git@github.com:rimusz-lab/bk-charts.git || true
 fi

 git fetch upstream
 git checkout gh-pages

 log "Initializing build directory with existing charts index"
 if [ -f index.yaml ]; then
   cp index.yaml "$BUILD_DIR"
 fi

 git checkout master

 # Package all charts and update index in temporary buildDir
 log "Packaging charts from source code"
 pushd "$BUILD_DIR"
   # shellcheck disable=SC2045
   for dir in $(ls "$REPO_DIR"/stable); do
     log "Packaging $dir"
     helm dep update "$REPO_DIR"/stable/"$dir" || true
     helm package "$REPO_DIR"/stable/"$dir"
   done

   log "Indexing repository"
   if [ -f index.yaml ]; then
     helm repo index --url ${REPO_URL} --merge index.yaml .
   else
     helm repo index --url ${REPO_URL} .
   fi
 popd

 git reset upstream/gh-pages
 cp "$BUILD_DIR"/* "$REPO_DIR"
 rm -fr .github

 # Commit changes are not enabled during PR
 if [ $COMMIT_CHANGES != "false" ]; then
   log "Commiting changes to gh-pages branch"
    # shellcheck disable=SC2035
   git add *.tgz index.yaml
   git commit --message "$COMMIT_MSG"
   git push -q upstream HEAD:gh-pages
 fi

 log "Repository cleanup and reset"
 git reset --hard upstream/master
 git clean -df .
 