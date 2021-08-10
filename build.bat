@echo off

cls 

call vcvars64

IF NOT EXIST build mkdir build

pushd build

del *.obj

odin build ../source/main.odin -out=../bin/application

popd