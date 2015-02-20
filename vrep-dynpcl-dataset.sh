#!/bin/bash

set -e

tol=${1:-0.01}
outdir=vrep-dynpcl-dataset

mkdir -p $outdir

for n in "bg" "dyn1"; do
    pcl_union_fast -t $tol vrep-pcl-${n}-{0..150}.pcd $outdir/$n.pcd
done
cp vrep-pcl-dyn2-0.pcd $outdir/scan.pcd

mv $outdir/{dyn1,s}.pcd

cd $outdir

pcl_intersection -t $tol s.pcd bg.pcd bg1.pcd
pcl_intersection -t $tol scan.pcd bg.pcd bg2.pcd
pcl_difference -t $tol scan.pcd bg.pcd dyn2.pcd
pcl_union -t $tol bg1.pcd bg2.pcd dyn2.pcd gt.pcd

