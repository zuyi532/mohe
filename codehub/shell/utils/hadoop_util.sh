#!/bin/bash
###########################################################################
#
# Copyright (c) 2015 Baidu.com, Inc. All Rights Reserved
#
##########################################################################
:<<'EOF'
    @brief 
    @author yangtongjiang(com@baidu.com)
    @date 2015/02/09 16:06:40
EOF

:<<'FUNC_DES'
    检查集群数据是否就绪，若未就绪则一直等待数据就绪，或者超出等待时间限制
    @param args[1] (必须) HADOOP_COMMAND
    @param args[2] (必须) 锚点，即要检查的文件或目录(推荐检测目录)
    @param args[3] (可选) 等待超时时间，单位是秒，不指定则默认一天
    @param args[4] (可选) 等待数据flush时间，单位是秒，不指定则默认30分钟
    @return_status {正常退出:0，参数异常:1，hadoop命令无效:2，超时:3}
FUNC_DES
function wait_for_data_ready(){
    if [ $# -lt 2 ];then
        return 1
    fi
    type BADM_INFO >/dev/null 2>&1
    if [ $? -ne 0 ];then
        source /home/yangtongjiang/workspaces/utils/log_util.sh
    fi

    local HADOOP_COMMAND=$1
    local chk_file=$2
    local wait_time=86400
    if [ $# -gt 2 ];then
        wait_time=$3
    fi
    local flush_time=1800
    if [ $# -gt 3 ];then
        flush_time=$4
    fi
    local wait_interval=$flush_time
    if [ $wait_interval -lt 1800 ];then
        wait_interval=1800
    fi

    chk_file=$(echo $chk_file | sed 's/\/\+$//')
    if [ -z "$chk_file" ];then
        BADM_ERROR "锚点目录不能是根目录！！"
        return 1
    fi

    type $HADOOP_COMMAND >/dev/null 2>&1
    if [ $? -ne 0 ];then
        BADM_ERROR "command not exist: $HADOOP_COMMAND"
        return 2
    fi

    BADM_NOTICE "check file exists: $chk_file"
    start_time=$(date +%s)
    ${HADOOP_COMMAND} fs -test -e $chk_file
    while [ $? -ne 0 ];do
        current=$(date +%s)
        let wt=$wait_time-$current+$start_time
        if [ $wt -lt 0 ];then
            BADM_NOTICE 'waiting-timeout; giving up...'
            return 3
        fi
        BADM_NOTICE "data not ready; sleep $wait_interval"
        sleep $wait_interval
        ${HADOOP_COMMAND} fs -test -e $chk_file
    done
    ${HADOOP_COMMAND} fs -test -d $chk_file
    if [ $? -eq 0 ];then
        file_type='dir'
        parent_dir=${chk_file%/*}
    else
        file_type='file'
        parent_dir=$chk_file
    fi
    BADM_NOTICE "check $file_type modify time: $chk_file"
    chk_time=`${HADOOP_COMMAND} fs -ls $parent_dir | grep "$chk_file" | awk '{print $6 " " $7}'`
    BADM_NOTICE "chk_time: $chk_time"
    chk_time=`date -d "$chk_time" +%s`
    if [ $? -ne 0 ];then
        BADM_ERROR "chk_time error"
        return 1
    fi
    current=`date +%s`
    let n=current-chk_time
    while [ $n -lt $flush_time ];do
        BADM_NOTICE 'data not ready; waiting for all data flush'
        sleep $flush_time
        chk_time=`${HADOOP_COMMAND} fs -ls $parent_dir | grep "$chk_file" | awk '{print $6 " " $7}'`
        chk_time=`date -d "$chk_time" +%s`
        BADM_NOTICE "chk_time: $chk_time"
        if [ $? -ne 0 ];then
            BADM_ERROR "chk_time error"
            return 1
        fi
        current=`date +%s`
        let n=current-chk_time
    done
}

#vim: set expandtab ts=4 sw=4 sts=4 tw=100
