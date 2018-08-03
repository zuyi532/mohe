#!/bin/bash
###########################################################################
#
# Copyright (c) 2015 Baidu.com, Inc. All Rights Reserved
#
##########################################################################
:<<'EOF'
    @brief 把集群多个小文件合并成一个
    @author yangtongjiang(com@baidu.com)
    @date 2015/05/03 17:34:07
EOF

function merge_small_file(){
    if [ $# -lt 2 ];then
        return 1
    fi

    local HADOOP_COMMAND=$1
    local HADOOP_DATA_DIR=$2

    if [[ ! "$HADOOP_DATA_DIR" =~ '^/app/ecom/ba/hive/warehouse/ytj.db/[^\/]' ]] || [[ "$HADOOP_DATA_DIR" =~ ' ' ]];then
        echo "HADOOP_DATA_DIR ERROR: $HADOOP_DATA_DIR" >&2
        return 2
    fi
    $HADOOP_COMMAND dfs -test -d $HADOOP_DATA_DIR
    if [ $? -ne 0 ];then
        return 3
    fi
    local file_num=$($HADOOP_COMMAND dfs -ls $HADOOP_DATA_DIR | wc -l)
    if [ $file_num -gt 10 ];then
        local file_name=$($HADOOP_COMMAND dfs -ls $HADOOP_DATA_DIR | head -2 | tail -1 | awk '{print $8}')
        local rand=$(cat /proc/sys/kernel/random/uuid| cksum|cut -d' ' -f1)
        rand=${rand}_$$

        local local_file=./data/ytj_${rand}_$(basename $file_name)
        local_file=$(mktemp $local_file)
        if [ -z "$local_file" ];then
            echo "mktemp file error" >&2
            return 4
        fi
        $HADOOP_COMMAND fs -cat $HADOOP_DATA_DIR/* > $local_file
        if [ $? -ne 0 ];then
            echo "merge_small_file error while cat files : $HADOOP_DATA_DIR" >&2
            return 5
        fi

        $HADOOP_COMMAND fs -rm $HADOOP_DATA_DIR/* && $HADOOP_COMMAND fs -moveFromLocal $local_file $file_name
    fi
}

function merge_subdir_files(){
    if [ $# -lt 2 ];then
        return 1
    fi
    local HADOOP_COMMAND=$1
    $HADOOP_COMMAND fs -ls $2 | awk '{if(NF>5){print $NF}}' | while read subdir;do
        echo "start dir: $subdir"
        merge_small_file $HADOOP_COMMAND $subdir
    done
}

#merge_small_file 'hadoop' '/app/ecom/ba/hive/warehouse/ytj.db/app_v1_new_inst_comparison/source=appsearch_l1/sample_type=3/time=20150126'
#merge_small_file 'hadoop' '/app/ecom/ba/hive/warehouse/ytj.db//app_v1_new_inst_comparison/source=appsearch_l1/sample_type=3/time=20150126'
#merge_small_file /home/liuxinmi/local/hadoop-client/hadoop/bin/hadoop /app/ecom/ba/hive/warehouse/ytj.db/app_v1_new_inst_comparison/source=appsearch_l1/sample_type=3/time=20150126

#vim: set expandtab ts=4 sw=4 sts=4 tw=100
