#!/usr/bin/env bash

cd src
rm -rf ../target
mkdir -p ../target
zip ../target/notification.zip *.*

cd ..