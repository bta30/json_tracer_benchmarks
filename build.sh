#!/bin/bash

cd benchmark_programs/Splash-3/codes &&
make &&
cd ../../../json_tracer &&
./build.sh &&
cd .. &&
touch built
