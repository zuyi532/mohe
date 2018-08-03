#!/bin/bash
###########################################################################
#
# Copyright (c) 2014 Baidu.com, Inc. All Rights Reserved
#
##########################################################################
:<<'EOF'
    @brief 日期抽样工具集，提供高度定制化的日期抽样。日期格式%Y%m%d，eg. 20141231
           ** 数据趋势本身随季度、月度、周度规律浮动，抽样计算时必须兼顾这种规律浮动，否则会造成人为数据偏差
    @author yangtongjiang(com@baidu.com)
    @date 2014/10/25 13:33:51
EOF

:<<'FUNC_DES'
 按周次抽样
 @param args[1] 抽样起始时间
 @param args[2] 结束时间
 @param args[3] 一周里抽取的日期，取值[0,6]，0代表周日，其他各自表示周几
 @return 正确，返回抽样计划；否则，输出空并输出错误信息到标准错误
 @ eg. 抽取20140501至20140815日所有周二和周四：sample_week 20140501 20140815 24
FUNC_DES
function sample_week(){
    from=$1
    to=$2
    weekdays=($(echo $3|sed 's/[0-9]/& /g'))
    week=(0 0 0 0 0 0 0)
    for weekday in ${weekdays[@]};do
        if [ $weekday -gt 6 ];then
            echo 'weekdays must be not greate than 5: [0,5]' >&2
            exit 1
        fi
        week[$weekday]=1
    done
    for ((i=$from;i<=$to;i=$(date -d "1 days $i" +%Y%m%d)));do
        w=$(date -d $i +%w)
        if [ ${week[$w]} -eq 1 ];then
            echo $i
        fi
    done
}

:<<'FUNC_DES'
 按月度-周次抽样
 @param args[1] 抽样起始时间
 @param args[2] 结束时间
 @param args[3] 每月抽样的周次，取值[0,4]，分别代表第一个周至第五个周[如要抽样周三，此参数代表要抽取每月的哪几个周三]
 @param args[4] 一周里抽取的日期，取值[0,6]，0代表周日，其他各自表示周几
 @return 正确，返回抽样计划；否则，输出空并输出错误信息到标准错误
 @ eg. 抽取2014年Q3中每月的第二和第三个周三、周五：sample_week_month 20140701 20140930 12 35
FUNC_DES
function sample_week_month(){
    from=$1
    to=$2
    weeks=$3
    weekdays=($(echo $4|sed 's/[0-9]/& /g'))
    days=''
    for weekday in ${weekdays[@]};do
        if [ $weekday -gt 6 ];then
            echo 'weekday must be not greate than 6: [0,6]' >&2
            exit 1
        fi
        j=$(get_first_weekday $from $weekday)
        dd=$(sample_1day_week_month $j $to $weeks)
        status_code=$?
        if [ $status_code -ne 0 ];then
            exit $status_code
        fi
        days="$days $dd"
    done
    echo $days | tr ' ' "\n" | sort
}

:<<'FUNC_DES'
 按月度抽取，指定周次中每周抽取一天(第几个周，从0计数; 起始日期隐含抽取的是周几)
 @param args[1] 抽样起始时间
 @param args[2] 结束时间
 @param args[3] 每月抽样的周次，取值[0,4]，分别代表第一个周至第五个周[如要抽样周三，此参数代表要抽取每月的哪几个周三]
 @return 正确，返回抽样计划；否则，输出空并输出错误信息到标准错误
 @ eg. 抽取2014年Q3中每月个第二和第三个周三：sample_1day_week_month 20140702 20140930 12
       [NOTICE]起始日期使用20140702是因为它是周三
FUNC_DES
function sample_1day_week_month(){
    from=$1
    to=$2
    weeks=($(echo $3|sed 's/[0-9]/& /g'))
    for week in ${weeks[@]};do
        if [ $week -gt 5 ];then
            echo 'weekth must be not greate than 5: [0,5]' >&2
            exit 1
        fi
    done
    weekday=$(date -d $from +%w)
    while [ $from -le $to ];do
        month=${from:0:6}
        first_weekday=$(get_first_weekday ${month}01 $weekday)
        for week in ${weeks[@]};do
            date=$(date -d "$week weeks $first_weekday" +%Y%m%d)
            if [ $date -ge $from ] && [ ${date:0:6} -eq $month ];then
                echo $date
            fi
        done
        from=$(get_first_weekday $(date -d "1 month $from" +%Y%m01) $weekday)
    done
}

#date formate: %Y%m%d
function sample_week_by_num_invterval(){
    from=$1
    to=$2
    num=$3
    if [ $# -gt 3 ];then
        invterval=$4
    else
        invterval=7
    fi
    if [ $to -lt 1 ];then
        exit 1
    fi
    balance=$(echo "7-$num*$invterval"|bc)
    if [ $balance -lt 0 ];then
        exit 1
    fi
    while [ $from -le $to ];do
        for ((i=1;i<=$num;i++));do
            echo $from
            from=$(date -d "$invterval days $from" +%Y%m%d)
        done
        if [ $balance -gt 0 ];then
            from=$(date -d "$balance days $from" +%Y%m%d)
        fi
    done
}

:<<'FUNC_DES'
 获取指定的日期，日期通过年、月、月中第几个、周几来指定
 @param args[1] year
 @param args[2] month => 1...12
 @param args[3] 月中的第几个周，从0计数
 @param args[4] 周几，取值[0,6]，0代表周日，其他各自表示周几
 @return 返回指定日期
 @ eg. 获取2014年5月第一个周一：get_assigned_date 2014 5 0 1
FUNC_DES
function get_assigned_date(){
    year=$1
    month=$2 #[1,12]
    week=$3 #counting from zero
    weekday=$4 #[0,6] or weekday%7, 0==7
    let offset=week*7
    date -d "$(( (7+$weekday-$(date -d "$year-$month-1" +%w))%7+$offset))day $year-$month-1" +%Y%m%d
}

:<<'FUNC_DES'
 计算指定两个日期的间隔天数
FUNC_DES
function get_date_interval(){
    local date1=$1
    local date2=$2
    if [ $date1 -gt $date2 ];then
        local dd=$date1
        date1=$date2
        date2=$dd
    fi
    local tt=$(($(date +%s -d $date2) - $(date +%s -d $date1)));
    echo "$tt/86400" | bc
}

:<<'FUNC_DES'
 获取从指定日期起的第一个周N
 @param args[1] 基准时间
 @param args[2] 周几 取值[0,6]，0代表周日
 @return 返回抽样计划
 @ eg. 抽取20150101后的第一个周二：get_first_weekday 20150101 2
FUNC_DES
function get_first_weekday(){
    dt=$1
    weekday=$2
    w=$(date -d $dt +%w)
    let interval=$weekday-$w
    if [ $interval -gt 0 ];then
        date -d "$interval days $dt" +%Y%m%d
    elif [ $interval -lt 0 ];then
        let interval=7+$interval
        date -d "$interval days $dt" +%Y%m%d
    else
        echo $dt
    fi
}

:<<'FUNC_DES'
 计算给定日期是月里的第几个周，从第一个完整周算作第一周
 @param args[1] 要计算的日期
 @param args[2] 一周的开始时间，0表示周日作为一周的开始，1表示周一作为一周的开始，默认是周日作为一周的统计
 @return 若给定日期是月初第一个非完整周，返回0；否则返回对应周次的[月末最后一个非完整周，仍按正整数正常返回]
FUNC_DES
function calc_weekth_of_month(){
    dt=$1
    first_day_of_week=0
    if [ $# -gt 1 ];then
        first_day_of_week=$2
        if [ $first_day_of_week -ne 0 ] && [ $first_day_of_week -ne 1 ];then
            echo '一周的开始时间只能取0和1，其中0表示周日作为一周的开始，1表示周一作为一周的开始' >&2
            exit 1
        fi
    fi
    year=$(date -d $dt +%Y)
    month=$(date -d $dt +%m)
    first_day=$(get_assigned_date $year $month 0 $first_day_of_week)
    tt=$(($(date +%s -d $dt) - $(date +%s -d $first_day)));
    weekth=0
    if [ $tt -ge 0 ];then
        let weekth=1+tt/604800
    fi
    echo $weekth
}

:<<'FUNC_DES'
 获取指定日期/月份，所在月的最后一天
 @param args[1] 指定的日期或月份，前6位格式为YYYYmm，如20141010、201410
FUNC_DES
function last_day_of_month(){
    if [[ ! "$1" =~ ^[0-9]{6} ]];then
        echo "输入日期/月份格式错误，前6位格式应为YYYYmm: $1" >&2
        exit 1
    fi
    local month=${1:0:6}
    local dd=$(date -d "1month ${month}01" +%Y%m%d)
    date -d "-1day $dd" +%Y%m%d
}

:<<'FUNC_DES'
获取从start到end的日期列表，含两端日期
 @param args[1] args[2] 开始和结束日期
FUNC_DES
function get_date_list(){
    if [ $# -lt 2 ];then
        echo '请输入起始和结束日期' >&2
        exit 1
    fi
    if [ $1 -gt $2 ];then
        from=$2
        to=$1
    else
        from=$1
        to=$2
    fi
    for ((i=$from;i<=$to;i=$(date -d "1 days $i" +%Y%m%d)));do
        echo $i
    done
}
#vim: set expandtab ts=4 sw=4 sts=4 tw=100
