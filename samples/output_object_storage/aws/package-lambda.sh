#!/usr/bin/env bash

cd src
rm -rf ../target
mkdir -p ../target
zip ../target/output-object-storage.zip *.*

cd ..