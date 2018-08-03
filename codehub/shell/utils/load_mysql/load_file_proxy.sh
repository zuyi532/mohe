#!/bin/bash
###########################################################################
#
# Copyright (c) 2015 Baidu.com, Inc. All Rights Reserved
#
##########################################################################
:<<'EOF'
    @brief 
    @author yangtongjiang(com@baidu.com)
    @date 2015/08/11 17:57:05
EOF

function usage(){
    s=load_file_proxy
    cat <<- _EOF_
	USAGE:$s --
	    -a 把auto_increment类型的也加入到要load的字段
	    -c charset [默认utf8]
	    -d 重复记录的处理方式
	    -D database [默认motaDB]
	    -f data file
	    -F fields 
	    -i interval time -- sleep time
	    -l 切分文件的行数，单位是万[最多支持切分成100个小文件]
	    -m 数据文件的最多行数
	    -r remote file -- 不指定则默认是本地文件
	    -s sql template -- 完整的load语句 [WARNINGS:它会屏蔽掉参数acdDfFrt]
	    -t table name
	e.g.:
	    $s -tindependent_app_day_report -f'./data/brand_weight_appsearch_l1_3_201507.txt'
	    $s -s"LOAD DATA LOCAL INFILE './data/brand_weight_appsearch_l1_3_201507.txt' INTO TABLE motaDB.independent_app_day_report(packageid,install,dau,avg_user_start_times,avg_user_time,download,new_install,active,uninstall,date)"
	_EOF_
}

function get_table_fields(){
    local db=$1
    local tb=$2
    local autoint=$3
    local sql="select column_name from information_schema.columns where table_name='$tb' and table_schema='$db'"
    if [ "$autoint" ];then
        sql="$sql and extra not like '%auto_increment%'"
    fi
    $MYSQL -N -e "$sql"
}

function load_file_proxy(){
    if [ -z "$MYSQL" ];then
        source /home/yangtongjiang/workspaces/mota/common/db_env.sh
    fi
    type BADM_INFO >/dev/null 2>&1
    if [ $? -ne 0 ];then
        source /home/yangtongjiang/workspaces/utils/log_util.sh
    fi

    local MAX_LINGES=15000000
    local LINE_THREHOLD=200000
    local autoint='auto_increment'
    local charset='utf8'
    local duplicate=''
    local db=$MOTA_DB
    local file=''
    local fields=''
    local interval_time=3
    local local_infile='LOCAL'
    local tb=''
    local sql_template=''
    while getopts :ac:d:D:f:i:l:m:rs:t: OPTION
    do
        case $OPTION in
            a )
                autoint=''
                ;;
            c )
                charset=$OPTARG
                ;;
            d )
                duplicate=$(echo $OPTARG | tr '[a-z]' '[A-Z]')
                if [ "$duplicate" != 'IGNORE' ] && [ "$duplicate" != 'REPLACE' ];then
                    echo "-d duplicate record only can be assigned as 'ignore' or 'replace'" >&2
                    return 1
                fi
                ;;
            D )
                db=$OPTARG
                ;;
            f )
                file=$OPTARG
                ;;
            F )
                fields=$OPTARG
                ;;
            l )
                let LINE_THREHOLD=$OPTARGA*10000
                ;;
            m )
                MAX_LINGES=0
                ;;
            r )
                #local_infile=''
                echo '暂仅支持LOCAL文件的LOAD操作' >&2
                return 1
                ;;
            t )
                tb=$OPTARG
                ;;
            s )
                sql_template=$OPTARG
                ;;
            \? )
                usage >&2
                return 1
                ;;
            : )
                echo "$0:Must supply an argument to -$OPTARG."  >&2
                usage >&2
                return 1
                ;;
        esac
    done
    unset OPTIND

    if [ "$sql_template" ];then
        load_sql=${sql_template%%\'*}
        db_sql=${sql_template##*\'}
        file=${sql_template#*\'}
        file=${file%\'*}
        if [ "${load_sql}'${file}'${db_sql}" != "$sql_template" ];then
            echo "sql template error: $sql_template" >&2
            return 2
        fi
    else
        if [ -z "$tb" ] || [ -z "$file" ];then
            echo "-f file must be given" >&2
            echo "-t table must be given" >&2
            return 1
        fi

        if [ -z "$fields" ];then
            fields=$(get_table_fields $db $tb $autoint | tr -s '\n' ',' | sed 's/,$//')
            if [ $? -ne 0 ] || [ -z "$fields" ];then
                echo "get table fields error" >&2
                return 3
            fi
        fi

        load_sql="LOAD DATA $local_infile INFILE"
        db_sql="INTO TABLE $db.$tb character set $charset ($fields)"
    fi

    sql_arr=("$load_sql" $file "$db_sql")

    if [ ! -s "$file" ];then
        echo "file not exists or is empty: $file" >&2
        return 2
    fi

    #file_size=$(du -m $file | cut -f1)
    file_lines=$(wc -l $file | cut -d' ' -f1)
    echo "file_lines: $file_lines"
    if [ $file_lines -gt $LINE_THREHOLD ];then
        if [ $file_lines -gt $MAX_LINGES ];then
            BADM_ERROR "file is too big, please check: [${file_lines}]$file"
            return 4
        fi
        echo "bigger than LINE_THREHOLD: $file_lines"
        rand_prefix=$(cat /proc/sys/kernel/random/uuid | cksum | cut -d' ' -f1)
        if [ -z "$rand_prefix" ];then
            BADM_ERROR 'get random error'
            return 3
        fi
        tmp_dir="${rand_prefix}_tmp_dir"
        mkdir $tmp_dir
        if [ $? -ne 0 ];then
            BADM_ERROR "mkdir $tmp_dir failed" 
            return 3
        fi
        split -l $LINE_THREHOLD -d $file $tmp_dir/mota_x
        if [ $? -ne 0 ];then
            BADM_ERROR "split file failed: $file"
            return 3
        fi
        split_files=($tmp_dir/*)
        for i in ${split_files[@]};do
            sql="${sql_arr[0]} '$i' $duplicate ${sql_arr[2]}"
            BADM_NOTICE "$sql"
            $MYSQL -e "$sql"
            if [ $? -ne 0 ];then
                BADM_ERROR "load mysql error[$i]"
                return 4
            fi
            sleep $interval_time
        done
        rm -r $tmp_dir
    else
        sql="${sql_arr[0]} '$file' $duplicate ${sql_arr[2]}"
        BADM_NOTICE "$sql"
        $MYSQL -e "$sql"
        if [ $? -ne 0 ];then
            BADM_ERROR "load mysql error[$file]"
            return 4
        fi
    fi

    BADM_NOTICE 'load file...done'
}

