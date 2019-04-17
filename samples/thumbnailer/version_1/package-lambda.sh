#!/usr/bin/env bash

cd src
npm install
rm -rf ../target
mkdir -p ../target
zip -r ../target/thumnailer.zip *.* node_modules

cd ..