#!/bin/bash

set -e

tol=0.01

if [ "$1" = "-t" ]; then
    shift
    tol=$1
    shift
fi

indir=raw

p_miss=0.0
p_hit=1.0

clamp_min=0.49
clamp_max=0.51

pcd_list() {
    local i
    for k in dyn1 dyn2; do
        i=0
        while [ -f $indir/vrep-pcl-$k-$i.pcd ]; do
            echo $indir/vrep-pcl-$k-$i.pcd
            i=$(($i + 1))
        done
    done
}

pcl_make_scanlog $(pcd_list) > scan.log
~/octomap/bin/log2graph scan.log scan.graph
rm scan.log
~/octomap/bin/graph2tree -res $tol -i scan.graph -o octomap.bt -sensor $p_miss $p_hit -clamping $clamp_min $clamp_max

