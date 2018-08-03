#!/bin/bash
###########################################################################
#
# Copyright (c) 2015 Baidu.com, Inc. All Rights Reserved
#
##########################################################################
:<<'EOF'
    @brief 
    @author yangtongjiang(com@baidu.com)
    @date 2015/03/13 21:27:45
EOF

MYSQL_cq01='mysql -hcq01-ba-data01.cq01 -P3307 -uroot -pbai_du@1xia'
MYSQL_3309='mysql -hcq01-ba-data01.cq01 -P3309 -uroot -pba_dm123. -N'
MYSQL='mysql -hcq01-ba-data01.cq01 -uroot -pbai_du@1xia -P3307 motaDB'
#MYSQL='mysql -uuBeBfyi6062 -pPStC0tohpS6xTsEAN -h10.91.160.114 -P6062 motaDB'

MOTA_DB='motaDB'
MY_DB='ytj'

APP_LIST_TB="$MY_DB.package_list"
CHECK_APP_LIST_TB="$MY_DB.check_app_list"
APP_DAY_REPORT_TB="$MOTA_DB.app_day_report"

APP_DETAIL_TB="$MOTA_DB.package_info_limit"

#vim: set expandtab ts=4 sw=4 sts=4 tw=100
