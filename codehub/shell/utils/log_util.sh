function BADM_INFO(){
	echo `date +"%Y-%m-%d %H:%M:%S"`" BADM_INFO $@" 
}

function BADM_TEST(){
	echo `date +"%Y-%m-%d %H:%M:%S"`" [TEST] $@" 
}

function BADM_NOTICE(){
	echo `date +"%Y-%m-%d %H:%M:%S"`" [NOTICE] $@" 
}

function BADM_ERROR(){
	echo `date +"%Y-%m-%d %H:%M:%S"`" [ERROR] $@" 
}

function BADM_WARNNING(){
	echo `date +"%Y-%m-%d %H:%M:%S"`" [WARNNING] $@" 
}
