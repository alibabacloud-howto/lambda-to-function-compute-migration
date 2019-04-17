#!/usr/bin/env bash

cd src
npm install
rm -rf ../target
mkdir -p ../target
zip -r ../target/output-notification.zip *.* node_modules

cd ..