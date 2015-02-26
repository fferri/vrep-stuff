#!/bin/bash

set -e

tol=0.01

if [ "$1" = "-t" ]; then
    shift
    tol=$1
    shift
fi

basename=${1:-result}

for f in dataset/{bg,gt,dyn2}.pcd result.pcd; do
    if [ ! -f "$f" ]; then
        echo "error: $f does not exist" 1>&2
        exit 1
    fi
done

if [ ! -f "${basename}-dyn.pcd" ]; then
    echo "info: ${basename}-dyn.pcd needs to be created"
    pcl_difference -t $tol ${basename}.pcd dataset/bg.pcd ${basename}-dyn.pcd
fi

J1="$(pcl_jaccard_similarity -t $tol ${basename}.pcd dataset/gt.pcd | grep ^jaccard | cut -d ' ' -f 4)"
echo "j1[$tol]: $J1"

J2="$(pcl_jaccard_similarity -t $tol ${basename}-dyn.pcd dataset/dyn2.pcd | grep ^jaccard | cut -d ' ' -f 4)"
echo "j2[$tlo]: $J2"

J1J2="$(python -c "print($J1*$J2)")"
echo "j1j2[$tol]: $J1J2"
