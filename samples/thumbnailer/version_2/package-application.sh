#!/usr/bin/env bash

cd src
npm install
rm -rf ../target
mkdir -p ../target
zip -r ../target/thumbnailer.zip *.* node_modules services drivers model

cd ..