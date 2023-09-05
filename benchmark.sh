#!/bin/bash

cd $(dirname $0)

splash3Path="benchmark_programs/Splash-3/codes"
fmmPath="$splash3Path/apps/fmm"
oceanContiguousPath="$splash3Path/apps/ocean/contiguous_partitions"
barnesPath="$splash3Path/apps/barnes"
radixPath="$splash3Path/kernels/radix"

# Given: Module Path
# Returns: Options to tracer for module
function getTracerOpts {
    echo "--exclude --instr --all --include --instr mov --exclude --module -N$1"
}

# Given: command stdinfile
# Output: time (in ms)
function timeCommand {
    start=$(($(date +%s%N)/1000000))
    $1 <"$2" >/dev/null
    end=$(($(date +%s%N)/1000000))
    echo "$((end - start))"
}

# Given: executable arguments traceropts stdinfile name particles threads
# Output: name,time,size,"eraserlockset"
function timeBenchmark {
    outputPrefix="$5"
    traceName=$outputPrefix.0000.log

    rm -f *.log
    time=$(timeCommand "$1 $2" $4)
    echo "$5,$6,$7,$time,0,normal"

    rm -f *.log
    time=$(timeCommand "./json_tracer/run.sh --output_interleaved --output_prefix $outputPrefix --exclude --module --all -- $1 $2" $4)
    size=$(du -sm $traceName | awk '{print $1}')
    echo "$5,$6,$7,$time,$size,filter_all"

    rm -f *.log
    time=$(timeCommand "./json_tracer/run.sh --output_interleaved --output_prefix $outputPrefix $3 -- $1 $2" $4)
    size=$(du -sm $traceName | awk '{print $1}')
    echo "$5,$6,$7,$time,$size,filter_some"
}

function benchmarkFMM {
    numParticles=(
        256
        2048
        16384
    )

    for i in "${numParticles[@]}"; do
        tracerOpts="$(getTracerOpts "$fmmPath/FMM")"
        timeBenchmark "$fmmPath/FMM" "" "$tracerOpts" "$fmmPath/inputs/input.1.$i" "FMM_1_$i" $i 1
    done
}

function benchmarkOceanContiguous {
    numParticles=(
        10
        18
        34
        66
        130
        258
        514
        1026
        2050
        4098
    )

    numThreads=(
        1
        2
        4
        8
        16
    )

    for i in "${numParticles[@]}"; do
        for j in "${numThreads[@]}"; do
            tracerOpts="$(getTracerOpts "$oceanContiguousPath/OCEAN")"
            timeBenchmark "$oceanContiguousPath/OCEAN" "-p$j -n$i" "$tracerOpts" "/dev/null" "OCEAN_CONTIGUOUS" $i $j 
        done
    done
}

function benchmarkRadix {
    numKeys=(
        1000
        2000
        4000
        8000
        16000
        32000
        64000
        128000
        256000
        512000
        1024000
        2048000
        4096000
        8192000
        16384000
    )
    
    numThreads=(
        1
        2
        4
        8
        16
    )

    for i in "${numKeys[@]}"; do
        for j in "${numThreads[@]}"; do
            tracerOpts="$(getTracerOpts "$radixPath/RADIX")"
            timeBenchmark "$radixPath/RADIX" "-p$j -n$i" "$tracerOpts" "/dev/null" "RADIX" $i $j
        done
    done
}

function benchmarkBarnes {
    numParticles=(
        1024
        2048
        4096
        8192
        16384
    )

    numThreads=(
        1
        2
        4
        8
        16
    )

    for i in "${numParticles[@]}"; do
        for j in "${numThreads[@]}"; do
            tracerOpts="$(getTracerOpts "$barnesPath/BARNES")"
            timeBenchmark "$barnesPath/BARNES" "" "$tracerOpts" "$barnesPath/inputs_new/n$i-p$j" "BARNES" $i $j
        done
    done
}

for i in {1..5}; do
    #benchmarkBarnes
    benchmarkOceanContiguous
    #benchmarkFMM
    #benchmarkRadix
done
