#!/bin/bash

./mk --test --cleanup
if [[ $? -ne 0 ]]; then
    exit 1
fi

rm -rf ./build-*
if [[ $? -ne 0 ]]; then
    exit 1
fi
