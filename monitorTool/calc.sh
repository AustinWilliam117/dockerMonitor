#!/bin/bash

#----------------------------------------------------------------------------------------------------
date_time=`date "+%Y_%m_%d_%H-%M-%S"`
server_log_path=/data/dengyuanjing/jmeter/monitorTool

# 初始服务数组
server_array=("dm_service" "nlu_service" "audiolistening" "audiolistening_1" "dm_service_2" "nlu_service_2" "voice_splicing_web" "user_manage_web_3.1" "usermanage" "sms-management" "redis_proxy_48_1" "redis_proxy_48_2" "sms-management_2")

echo "-----------------------------------------------------------------------------------------------"
echo "生成的目录名称是：$date_time"
#printf '\n'
#printf '0.dialer\t1.piod\t2.mrcp\t3.vcg_3.3.2_hisense_docker\t4.nlp_management\t5.dm_service\t6.nlp_management_web\t7.nlu_service\t8.content_service\t9.classify_service\n'
printf '\n'
#read -p "是否监控freeSwitch(y/n)：" freeSwitchJudgment
#read -p "请输入要监控的服务序号(空格分隔)：" number
#read -p "请输入要监控的时长(分钟)：" server_time

freeSwitchJudgment=n
number=(0 1 2 3 4 5 6 7 8 9 10 11 12)
server_time=300

# 获取用户输入的长度（不包括空格）
# num=`echo $number | awk -F " " '{print NF}'`

# 用户指定要监控的数组
select_array=()

if [ $freeSwitchJudgment == "y" ]; then
    echo "您选择了监控freeSwitch"
fi

for i in ${number[@]}
do
    select_array[${#select_array[@]}]=${server_array[$i]}
done

echo "您所选择的监控有：${select_array[@]}"


#----------------------------------------------------------------------------------------------------
# 使用下面命令生成1.txt
# docker stats dialer > dialer.txt

# 存放log的路径
#LOG_PATH=/home/dengyuanjing/docker/test/$date_time/$server/
PID_array=()

if [ $freeSwitchJudgment == "y" ]; then
    log_path=$server_log_path/$date_time/freeSwitch
    mkdir -p $log_path
    log_result_path=$log_path/result
    mkdir -p $log_result_path

    # 获取fs进程号
    fs_PID=`ps -ef |grep freeswitch | grep -v grep | awk '{print $2}'`
fi


for server in ${select_array[@]}
do
    log_path=$server_log_path/$date_time/$server
    mkdir -p $log_path
    log_result_path=$log_path/result
    mkdir -p $log_result_path
    # 后台监控docker进程
    nohup docker stats $server > $log_path/$server.txt 2>& 1 &
    # 将各个服务的进程号记录的数组中
    PID_array[${#PID_array[@]}]=$!
done

# 输出PID_array的值
# ps -ef | grep "docker stats dialer"
for i in ${PID_array[@]}
do
    echo "所监控的进程ID为: $i"
done

if [ $freeSwitchJudgment == "y" ]; then
    # fs监控时间 == sleep ${server_time}m
    allTime=$(($server_time*60))
    fsTime=0
    log_path=$server_log_path/$date_time/freeSwitch
    log_result_path=$log_path/result
    while [ $fsTime -lt ${allTime} ]
    do
        # 监控内存
        top -n 1 -b | grep $fs_PID | awk '{print $10}' >> $log_result_path/fsmem.txt
        # 监控cpu
        top -n 1 -b | grep $fs_PID | awk '{print $9}' >> $log_result_path/fscpu.txt

        sleep 1
        fsTime=`expr $fsTime + 5`

    done
else
    sleep ${server_time}s

fi

# kill 掉监控进程
for server_PID in ${PID_array[@]}
do
    kill -9 $server_PID
done

sleep 5s

#----------------------------------------------------------------------------------------------------
# 过滤docker监控的文本

for server in ${select_array[@]}
do
    log_path=$server_log_path/$date_time/$server
    log_result_path=$log_path/result/
    #echo "现在要过滤的server名称为：$server"
    #echo "路径为：$log_path/$server.txt"
    # 1.过滤出Container ID
    cat $log_path/$server.txt |awk 'NR==2 {print $1}' | grep -v CONTAINER > CONTAINER.log
    # 2.过滤出容器名
    cat $log_path/$server.txt |awk 'NR==2 {print $2}' > CONTAINER_NAME.log
    # 3.过滤出CPU
    cat $log_path/$server.txt |awk '{print $3}' | grep -v NAME > CPU_Usage.log
    # 4.过滤出使用内存
    cat $log_path/$server.txt |awk '{print $4}' | grep -v CPU > MEM_Usage.log
    # 5.过滤出内存占比
    cat $log_path/$server.txt |awk '{print $7}' | grep -v USAGE > MEM_Rate.log
    # 6.过滤出发送数据量Net I
    cat $log_path/$server.txt |awk '{print $8}' | grep -v USAGE |grep -v / > NET_input.log
    # 7.过滤出接受数据量Net O
    cat $log_path/$server.txt |awk '{print $10}' | grep -v USAGE |grep -v 'MEM' > NET_output.log
    # 8.过滤出块读取数据量Block 
    cat $log_path/$server.txt |awk '{print $11}' | grep -v "%" > Block_input.log
    # 9.过滤出块写入数据量Block O
    cat $log_path/$server.txt |awk '{print $13}' | grep -v "I/O" > Block_output.log
    # 10.过滤出容器线程数Pids
    # PIDS=cat $log_path/$server.txt |awk '{print $14}' | grep -v "BLOCK"

    # 将日志移入LOG_PATH下
    mv CONTAINER.log $log_result_path
    mv CONTAINER_NAME.log $log_result_path
    mv CPU_Usage.log $log_result_path
    mv MEM_Usage.log $log_result_path
    mv MEM_Rate.log $log_result_path
    mv NET_input.log $log_result_path
    mv NET_output.log $log_result_path
    mv Block_input.log $log_result_path
    mv Block_output.log $log_result_path
    
done

#----------------------------------------------------------------------------------------------------
# 计算

echo $date_time >> $server_log_path/$date_time/calc.log

for server in ${select_array[@]}
do
    log_path=$server_log_path/$date_time/$server
    log_result_path=$log_path/result/
    python3 calc.py $log_result_path $server

    # 打印
    sleep 5
    log_result_path=$log_path/result
    cat $log_result_path/calc.txt
    cat $log_result_path/calc.txt >> $server_log_path/$date_time/calc.log
    echo ""
done

# 计算fs
if [ $freeSwitchJudgment == "y" ]; then
    log_path=$server_log_path/$date_time/freeSwitch
    log_result_path=$log_path/result/
    python3 calc.py $log_result_path freeSwitch
    cat $log_result_path/calc.txt
    cat $log_result_path/calc.txt >> $server_log_path/$date_time/calc.log
    echo ""
fi

echo "===========================" >> $server_log_path/$date_time/calc.log
echo ""  >> $server_log_path/$date_time/calc.log
