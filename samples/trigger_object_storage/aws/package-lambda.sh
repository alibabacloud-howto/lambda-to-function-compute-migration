#!/usr/bin/env bash

cd src
rm -rf ../target
mkdir -p ../target
zip ../target/object_storage.zip *.*

cd ..