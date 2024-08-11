#!/bin/bash

./mk --test --cleanup --toolchain sources/Test-toolchain.cmake
if [[ $? -ne 0 ]]; then
    exit 1
fi

rm -rf ./build-*
if [[ $? -ne 0 ]]; then
    exit 1
fi
