#!/usr/bin/env bash

cd src
npm install
rm -rf ../target
mkdir -p ../target
zip -r ../target/outpg.zip *.* node_modules services repositories drivers model

cd ..