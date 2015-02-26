#!/bin/bash

set -e

tol=0.01

if [ "$1" = "-t" ]; then
    shift
    tol=$1
    shift
fi

for f in result bg gt dyn2; do
    if [ ! -f "$f.pcd" ]; then
        echo "error: $f.pcd does not exist" 1>&2
        exit 1
    fi
done

if [ ! -f "result-dyn.pcd" ]; then
    echo "info: result-dyn.pcd needs to be created"
    pcl_difference -t $tol result.pcd bg.pcd result-dyn.pcd
fi

J1="$(pcl_jaccard_similarity -t $tol result.pcd gt.pcd | grep ^jaccard | cut -d ' ' -f 4)"
echo "j1: $J1"

J2="$(pcl_jaccard_similarity -t $tol dyn2.pcd result-dyn.pcd | grep ^jaccard | cut -d ' ' -f 4)"
echo "j2: $J2"

J1J2="$(python -c "print($J1*$J2)")"
echo "j1j2: $J1J2"
