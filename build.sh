#!/bin/bash
clear
echo "Building..."
if [ ! -d ./build ]
then
    mkdir ./build
fi

cd ./build

odin build ../source/main.odin -out=../bin/application

echo "Done!"