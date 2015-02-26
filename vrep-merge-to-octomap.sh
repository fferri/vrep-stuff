#!/bin/bash

set -e

tol=0.01

if [ "$1" = "-t" ]; then
    shift
    tol=$1
    shift
fi

indir=raw
outdir=dataset

p_miss=0.0
p_hit=1.0

mkdir -p $outdir

pcl_make_scanlog vrep-pcl-dyn1-{0..150}.pcd vrep-pcl-dyn2-0.pcd > $outdir/scan.log
~/octomap/bin/log2graph $outdir/scan.log $outdir/scan.graph
rm $outdir/scan.log
~/octomap/bin/graph2tree -res $tol -g -i $outdir/scan.graph -o $outdir/octomap.bt -sensor $p_miss $p_hit

