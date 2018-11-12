#!/bin/bash -e
 # USAGE: repo-sync.sh <commit-changes?>

 log() {
   echo -e "\033[0;33m$(date "+%H:%M:%S")\033[0;37m ==> $1."
 }

 install_helm_cli() {
   export HELM_URL=https://storage.googleapis.com/kubernetes-helm
   export HELM_TARBALL=helm-v2.11.0-linux-amd64.tar.gz
   wget -q ${HELM_URL}/${HELM_TARBALL}
   tar xzfv ${HELM_TARBALL}
   PATH=`pwd`/linux-amd64/:$PATH
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
 : ${COMMIT_CHANGES:=false}
 : ${TRAVIS:=false}
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
   cp index.yaml $BUILD_DIR
 fi

 git checkout master

 # Package all charts and update index in temporary buildDir
 log "Packaging charts from source code"
 pushd $BUILD_DIR
   for dir in `ls $REPO_DIR/stable`;do
     log "Packaging $dir"
     helm dep update $REPO_DIR/stable/$dir || true
     helm package $REPO_DIR/stable/$dir
   done

   log "Indexing repository"
   if [ -f index.yaml ]; then
     helm repo index --url ${REPO_URL} --merge index.yaml .
   else
     helm repo index --url ${REPO_URL} .
   fi
 popd

 git reset upstream/gh-pages
 cp $BUILD_DIR/* $REPO_DIR

 # Commit changes are not enabled during PR
 if [ $COMMIT_CHANGES != "false" ]; then
   log "Commiting changes to gh-pages branch"
   git add *.tgz index.yaml
   git commit --message "$COMMIT_MSG"
   git push -q upstream HEAD:gh-pages
 fi

 log "Repository cleanup and reset"
 git reset --hard upstream/master
 git clean -df .
 