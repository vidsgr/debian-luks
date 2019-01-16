#!/bin/bash

BASE=`realpath $(dirname $0)/..`

if [ -d $BASE/overlays/customization ]; then
  rsync -rlptD $BASE/overlays/customization/ /scratch/root/
fi
