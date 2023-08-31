#!/bin/bash

cd $(dirname $0)/benchmark_programs/Splash-3/codes &&
make &&
cd ../../../json_tracer &&
./build.sh &&
cd .. &&
touch built
