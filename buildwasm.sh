#!/usr/bin/env bash

mkdir -p out
rm -rf out/web out/draclove_web.zip
npx love.js --memory 41943040 -c -t draclove draclove-love out/web
rm -r out/web/theme
cp misc/index.html out/web
# miniserve --index index.html out/web
zip -r out/draclove_web.zip out/web