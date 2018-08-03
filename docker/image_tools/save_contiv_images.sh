#!/bin/bash
###########################################################################
#
# Copyright (c) 2018 Baidu.com, Inc. All Rights Reserved
#
##########################################################################
:<<'EOF'
    @brief 
    @author ytj689(com@ytj.io)
    @date 2018/06/02 14:26:59
EOF

set -e
set -u

image_kw='contiv'
output_dir='contiv'

function pull_images {
    images='contiv/alpine contiv/netplugin:1.1.9 contiv/ovs:1.2.1 contiv/stats contiv/auth_proxy:1.1.9 contiv/netplugin-init:1.2.1 contiv/nc-busybox contiv/v2plugin contiv/util-busybox contiv/ubuntu contiv/install:1.1.9 contiv/contiv-ui contiv/web contiv/netplugin-etcd-init'

    for image in $images;do
        echo "start... pull $image"
        docker pull $image
        echo "done... pull $image"
    done
}

function getImages {
    docker images | grep $image_kw | awk '{print $1":"$2}'
}

function save_images {
    image=$1
    #image_name=${image##*/}
    image_name=${image//\//_}
    image_name=${image_name%:*}
    tar_f="$output_dir/${image_name}.tar"
    if [[ -e $tar_f ]] || [[ -e ${tar_f}.gz ]];then
        return 0
    fi
    cmd="docker save -o$tar_f $image"
    echo $cmd
    $cmd
    gzip $tar_f
}

pull_images

images=$(getImages)

for i in $images;do
    echo "export image: $i"
    save_images $i
done

#vim: set expandtab ts=4 sw=4 sts=4 tw=100
