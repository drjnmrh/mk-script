#!/bin/bash

./mk --test --cleanup --tocmake -DCUSTOM_OPTION=ON
if [[ $? -ne 0 ]]; then
    exit 1
fi

rm -rf ./build-*
if [[ $? -ne 0 ]]; then
    exit 1
fi
