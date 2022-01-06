#!/bin/bash
# install/uninstall script
# To use as an install script, optionally set the following environment variables and run install.sh
#
#   NAME: project name (default: {{{LIB}}})
#   SOURCE_DIR: directory whose contents to copy (default: {{{LIB}}})
#   PREFIX: destination prefix (default:~/.local)
#
# To use as an uninstall script, add a symlink from uninstall.sh to install.sh

#############
# Variables
#############

OS=$(uname -s)
SCRIPT_NAME=$(basename $0)
SCRIPT_NAME=${SCRIPT_NAME%.*}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DEFAULT_PREFIX=${HOME}/.local

if [ ${SCRIPT_NAME} == "uninstall" ]; then
    INSTALL_ECHO=false
else
    INSTALL_ECHO=echo
fi

: "${NAME={{{LIB}}}}"
: "${SOURCE_DIR=${SCRIPT_DIR}/${NAME}}"
: "${PREFIX=${DEFAULT_PREFIX}}"

SHARE_DIR=${PREFIX}/share/${NAME}

FILES=${SHARE_DIR}/${NAME}-files.lst
DIRS=${SHARE_DIR}/${NAME}-dirs.lst

#################
# Functions
#################

die() { echo -e "\033[31m$*\033[0m"; exit 1; }

remove_files() {
    type=$1
    files=$2
    if [ -f ${files} ]; then
        echo "Removing old $type (${files})"
        cat ${files} | xargs rm -f
        rm -f ${files} || die "Unable to remove ${files}"
    fi
}

remove_dirs() {
    type=$1
    dirs=$2
    if [ -f ${dirs} ]; then
        echo "Removing old $type directories (${dirs})"
        cat ${dirs} | xargs rmdir -p > /dev/null 2>&1
        rm -f ${dirs} || die "Unable to remove ${dirs}"
    fi
}


prefix_in_lib_path() {
    ldconfig -N -v 2> /dev/null | grep : | sed -e 's/://' | grep -x "${PREFIX}/lib" > /dev/null 2>&1
}

update_lib_search_path() {
    if [ $OS == "Linux" ]; then
        if prefix_in_lib_path; then
            echo "Running ldconfig"
            ldconfig || sudo ldconfig
        else
            ${INSTALL_ECHO} "Be sure to add $PREFIX/lib to LD_LIBRARY_PATH"
        fi
    else 
        if [ $OS == "Darwin" ]; then
            ${INSTALL_ECHO} "Be sure to add $PREFIX/lib to DYLD_FALLBACK_LIBRARY_PATH if it is not a standard library path"
        fi
    fi
}

sudo_mkdir() {
    dir=$1

    echo "Attempting to sudo mkdir $dir"
    group=$(id -gn $USER)
    sudo mkdir -p $dir && sudo chown $USER:$group $dir
}

check_dest_dirs () {
    prefix=$1
    source_dir=$2

    # Create $prefix if necessary
    mkdir -p ${prefix} > /dev/null 2>&1
    if [ ! -d ${prefix} ]; then
        die "Unable to find or create ${prefix} directory"
    fi

    for dir in $(cd ${source_dir} && find . -maxdepth 1 -mindepth 1 -type d); do
        path=${prefix}/${dir#./}
        echo -n "Checking ability to create and write to $path... "

        RMDIR=0

        if [ ! -d ${path} ]; then
            mkdir -p ${path} > /dev/null 2>&1 && RMDIR=1 || sudo_mkdir ${path}
        else
            RMDIR=0
        fi

        TEST_FILE=${path}/__${NAME}__
        touch ${TEST_FILE} > /dev/null 2>&1 || die "You don't have permission to write to ${path}"
        rm -f ${TEST_FILE} > /dev/null 2>&1 || die "Unable to remove ${TEST_FILE}"

        if [ $RMDIR ]; then
            rmdir ${path} > /dev/null 2>&1
        fi
        
        echo "success"
    done
}

###########
# Main
###########

# Remove old files
remove_files files ${FILES}
remove_dirs "" ${DIRS}

# Remove share directory (where file/dir lists are stored)
rmdir -p ${SHARE_DIR} > /dev/null 2>&1

# If we're just uninstalling, stop here
if [ ${SCRIPT_NAME} == "uninstall" ]; then
    update_lib_search_path
    exit 0
fi

# Create $PREFIX if necessary
check_dest_dirs ${PREFIX} ${SOURCE_DIR}

mkdir -p ${SHARE_DIR} > /dev/null 2>&1 || die "Unable to create ${SHARE_DIR}"

echo "Copying files to ${PREFIX}"
(cd ${SOURCE_DIR} && find * -type d) | xargs -n1 -I{} echo ${PREFIX}/{} > ${DIRS}
(cd ${SOURCE_DIR} && find * -type f) | xargs -n1 -I{} echo ${PREFIX}/{} > ${FILES}
(cd ${SOURCE_DIR} && find * -type l) | xargs -n1 -I{} echo ${PREFIX}/{} >> ${FILES}
cp -a ${SOURCE_DIR}/* ${PREFIX}/ || die "Unable to copy files"

update_lib_search_path
