#!/usr/bin/env bash

mkdir -p out
zip -9 -r out/draclove.zip draclove-love
cat misc/love.exe out/draclove.zip > out/salvia.exe