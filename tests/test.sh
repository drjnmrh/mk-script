#!/bin/bash

OLDWD=$(pwd)

MYDIR="$(cd "$(dirname "$0")" && pwd)"
OLDDIR=${PWD}

for dir in ${MYDIR}/*/
do
    if [[ -f "${dir}flags.sh" ]]; then
        cd ..
        _flags=$(source ${dir}flags.sh)
        if [[ $? -ne 0 ]]; then
            echo "ERROR in the test script!"
            cd $OLDDIR
            exit 1
        fi

        ./mk $_flags
        if [[ $? -ne 0 ]]; then
            echo "TEST($dir) FAILED"
            cd $OLDDIR
            exit 1
        fi

        rm -rf build-*
        if [[ $? -ne 0 ]]; then
            echo "ERROR in the test script!"
            cd $OLDDIR
            exit 1
        fi
        cd $OLDDIR
    fi

    if [[ -f "${dir}run.sh" ]]; then
        cp ../mk ${dir}
        if [[ $? -ne 0 ]]; then
            echo "ERROR in the test script!"
            cd $OLDDIR
            exit 1
        fi
        cd ${dir}
        ./run.sh
        if [[ $? -ne 0 ]]; then
            echo "TEST($dir) FAILED"
            cd $OLDDIR
            exit 1
        fi
        rm mk
        if [[ $? -ne 0 ]]; then
            echo "ERROR in the test script!"
            cd $OLDDIR
            exit 1
        fi
        cd $OLDDIR
    fi
done
echo SUCCESS

