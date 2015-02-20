#!/bin/bash

set -e

tol=${1:-0.01}
outdir=vrep-dynpcl-dataset

p_miss=0.0
p_hit=1.0

mkdir -p $outdir

./pcl-boolean-op/pcl_make_scanlog.sh vrep-pcl-dyn1-{0..150}.pcd vrep-pcl-dyn2-0.pcd > $outdir/scan.log
./octomap/bin/log2graph $outdir/scan.log $outdir/scan.graph
rm $outdir/scan.log
./octomap/bin/graph2tree -res $tol -g -i $outdir/scan.graph -o $outdir/octomap.bt -sensor $p_miss $p_hit

./octomap/bin/octovis $outdir/octomap.bt &

