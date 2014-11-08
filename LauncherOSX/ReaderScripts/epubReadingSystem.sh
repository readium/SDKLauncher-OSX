#!/bin/sh

echo "###########################################"
echo "###########################################"

pwd=`pwd`
echo "Path:"
echo "${pwd}"
echo "------"

JS_FILE="${pwd}/LauncherOSX/ReaderScripts/epubReadingSystem.js"
echo "Javascript output:"
echo "${JS_FILE}"
echo "------"

FIRST=""

GitDo() {
ROOT_DIR=$1
SUB_DIR=$2
SUBMODULE=$3

cd "${SUB_DIR}"

echo "========================="
echo "Git submodule:"
echo "${SUBMODULE}"
echo "------"

GIT_DIR="${ROOT_DIR}/.git"
echo "Git directory:"
echo "${GIT_DIR}"
echo "------"

GIT_CWD="${SUB_DIR}"
#test -d "${GIT_CWD}" || GIT_CWD="${SUB_DIR}"
echo "Git submodule directory:"
echo "${GIT_CWD}"
echo "------"

GIT_DIR_CWD=""
# GIT_DIR_CWD="--git-dir=${GIT_DIR} --work-tree=${GIT_CWD}"
# echo "Git path spec:"
# echo "${GIT_DIR_CWD}"
# echo "------"

GIT_HEAD=`cat "${GIT_DIR}/HEAD"`
echo "Git HEAD:"
echo "${GIT_HEAD}";
echo "------"

test "${GIT_HEAD#'ref: '}" != "${GIT_HEAD}" && echo "(attached head)" && GIT_SHA=`git ${GIT_DIR_CWD} rev-parse --verify HEAD`
test "${GIT_HEAD#'ref: '}" == "${GIT_HEAD}" && echo "(detached head)" && GIT_SHA="${GIT_HEAD}"

echo "Git SHA:"
echo "${GIT_SHA}"
echo "------"

GIT_TAG=`git ${GIT_DIR_CWD} describe --tags --long ${GIT_SHA}`
echo "Git TAG:"
echo "${GIT_TAG}"
echo "------"

GIT_STATUS=`git ${GIT_DIR_CWD} status --porcelain`
echo "Git STATUS:"
echo "${GIT_STATUS}"
echo "------"

GIT_CLEAN=false
test -z "${GIT_STATUS}" && GIT_CLEAN=true
echo "Git CLEAN:"
echo "${GIT_CLEAN}"
echo "------"

echo "FIRST:"
echo "${FIRST}"
echo "------"

test -z "${FIRST}" && echo $"" > "${JS_FILE}"
FIRST="false"

echo "ReadiumSDK.READIUM_${SUBMODULE}_sha = '${GIT_SHA}';" >> "${JS_FILE}"
echo "ReadiumSDK.READIUM_${SUBMODULE}_tag = '${GIT_TAG}';" >> "${JS_FILE}"
echo "ReadiumSDK.READIUM_${SUBMODULE}_clean = '${GIT_CLEAN}';" >> "${JS_FILE}"

}

GitDo "${pwd}" "${pwd}" "OSX"
GitDo "${pwd}" "${pwd}/readium-sdk" "SDK"
GitDo "${pwd}" "${pwd}/readium-shared-js" "SHARED_JS"

READIUM_dateTimeString=`date`

echo "ReadiumSDK.READIUM_dateTimeString = '${READIUM_dateTimeString}';" >> "${JS_FILE}"

cat ${JS_FILE}

cd "${pwd}"

echo "###########################################"
echo "###########################################"