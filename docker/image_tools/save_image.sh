#!/bin/bash
###########################################################################
#
# Copyright (c) 2018 Baidu.com, Inc. All Rights Reserved
#
##########################################################################
:<<'EOF'
    @brief 
    @author ytj689(com@ytj.io)
    @date 2018/06/02 14:49:46
EOF
set -e
set -u

output_dir='images'

image=$1
image_name=${image##*/}
image_name=${image_name/:/-}
#image_name=${image_name%:*}
tar_f="$output_dir/${image_name}.tar"
cmd="docker save -o$tar_f $image"
echo $cmd
$cmd
gzip $tar_f


#vim: set expandtab ts=4 sw=4 sts=4 tw=100
