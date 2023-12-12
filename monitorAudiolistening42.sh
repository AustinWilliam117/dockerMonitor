#!/bin/bash

# 小程序单实例版本，多实例执行会报错，原因是找不到对应的PID。
# 执行脚本可能造成grep多个PID情况，届时请核对该脚本grep的内容

#-----------------配置项-----------------
#jmeterFile=zyzx_audio_2_2.jmx              #jmeter文件
jmeterFile=zyzx_yc_7.jmx                    #jmeter文件
#jmeterFile=zyzx_audio_nlp1.jmx             #jmeter文件

thread=(4)                                 #并发数
#thread=(8)                                 #并发数

stressProt=9090                             #压测端口 9800/9802 为单小程序, 9090为多实例

# 43200=12小时，21600=6小时，86400=24小时，259200=3天，14400=4小时
duration=120                                #循环持续时间（该版本为永久循环版本）

ramp_time=1                                 #花费多久的时间启动全部的线程

# 小程序端口号
#Ports=(9800 9802 9002 9001 19248 29001 29002 19249)
Ports=(19842)

basePath=/data/voice_bot_4.2
jmeterPath=/data/dengyuanjing/jmeter

# 容器监控脚本路径
monitorCalc=$jmeterPath/monitorTool

# 小程序日志路径
AUDIOlog_path=$basePath/audiolistening_arm/logs
AUDIO1log_path=$basePath/audiolistening_arm/audio_1/logs
AUDIO2log_path=$basePath/audiolistening_arm/audio_2/logs

# 短信日志路径
smsLogPath=$basePath/sms-management/logs
sms_1_LogPath=$basePath/sms-management/sms_1/logs

# 推送日志路径
pushKafkaLogPath=$basePath/push-kafka/pushKafka_1/logs
pushKafka_1_LogPath=$basePath/push-kafka/pushKafka_2/logs

# 要打印的小程序日志
audioLogArray=("$AUDIO1log_path" "$AUDIO2log_path")
# 要打印推送日志
pushKafkaLogArray=("$pushKafkaLogPath" "$pushKafka_1_LogPath")
# 要打印短信日志
smsLogArray=("$smsLogPath" "$sms_1_LogPath")

logFile=$jmeterPath/jmeterResult

# jmeter生成文件路径
jmeterCreatePath=$jmeterPath

# jmeter启动路径
jmeterStartPath=$jmeterPath/apache-jmeter-5.5/bin
# 注意：小程序连接数需要监控多个进程，目前只能主动填写
# python打印的并发数是一个占位值，可以填写真实的值
#-----------------配置项-----------------
# 日志格式化函数, 参数 $1: 需要备份日志路径及文件名。 $2: 程序名称 已经文件名，例如：audioListening al_db_dm.log。 $3: 是否需要统计入库，例如：y/n。 $4:入库的关键字，例如：入库完成
log_statistics() {
    echo "-------------------"
    # 需要备份的日志文件
    # cp $AUDIOlog_path/al_db_dm.log $AUDIOlog_path/al_db_dm.log_{$current_time}_bak
    cp $1 ${1}_${current_time}_bak
    # 打印日志中错误的数量
    # echo -n "audioListening al_db_dm.log Error 数量是: " && cat $AUDIOlog_path/al_db_dm.log_{$current_time}_bak | grep -ai "error" | wc -l
    echo -n "$1 Error 数量是: " && cat ${1}_${current_time}_bak | grep "ERROR" | wc -l
    # 是否需要打印日志中完成的数量，需要的话，传入完成的关键字
    # audioNum=`cat $AUDIOlog_path/al_db_dm.log_{$current_time}_bak | grep "入库完成" | wc -l`
    # echo -n "audioListening 入库数量是: " && echo "$audioNum"
    if [ $2 == 'y' ]; then
        countNum=`cat $1_${current_time}_bak | grep "$3" | wc -l`
        echo -n "$1 入库数量是: " && echo "$countNum"
        # 统计最后一条日志的时间
        # echo -n "audioListening 最后一条数据入库时间是: " && cat $AUDIOlog_path/al_db_dm.log_{$current_time}_bak | grep "整通通话入库完成" | tail -1 | awk '{print $1,$2}'
        echo -n "$1 最后一条数据入库时间是: " && cat ${1}_${current_time}_bak | grep "$3" | tail -1 | awk '{print $1,$2}'
        #return $countNum
    fi
}

# 小程序日志
# countNum=0
# audioNum=0
# for path in ${!audioLogArray[@]}
# do
#     # 小程序 al_db_dm_1
#     logPathAndName="${audioLogArray[$path]}/al_db_dm.log"
#     statisticsStorage=y
#     statisticsKeyWords="整通通话入库结束"
#     log_statistics $logPathAndName $statisticsStorage $statisticsKeyWords

#     audioNum=$((audioNum + countNum))

#     # 小程序 al_dm_1
#     logPathAndName="${audioLogArray[$path]}/al_dm.log"
#     statisticsStorage=n
#     log_statistics $logPathAndName $statisticsStorage $statisticsKeyWords
# done
# echo ""
# echo "小程序入库总数量是：$audioNum"
# echo ""
# 日志的二次封装
logPrintAudio() {
    local countNum=0
    local audioNum=0
    for path in ${!audioLogArray[@]}
    do
        # 小程序 al_db_dm_1
        logPathAndName="${audioLogArray[$path]}/${1}"
        statisticsStorage=y
        statisticsKeyWords="整通通话入库结束"
        log_statistics $logPathAndName $statisticsStorage $statisticsKeyWords

        audioNum=$((audioNum + countNum))

        # 小程序 al_dm_1
        logPathAndName="${audioLogArray[$path]}/${2}"
        statisticsStorage=n
        log_statistics $logPathAndName $statisticsStorage $statisticsKeyWords
    done
    echo ""
    echo "小程序入库总数量是：$audioNum"
    echo ""
}

# # 上传计费 push_kafka 日志
# countNum=0
# audioNum=0
# for path in ${!pushKafkaLogArray[@]}
# do
#     logPathAndName="${pushKafkaLogArray[$path]}/push-kafka.log"
#     statisticsStorage=y
#     statisticsKeyWords="推送callId"
#     log_statistics $logPathAndName $statisticsStorage $statisticsKeyWords

#     audioNum=$((audioNum + countNum))
# done
# echo ""
# echo "推送总数量是：$audioNum"
# echo ""

# 推送/短信二次封装
logPrintPushAndSms() {
    # 上传计费 push_kafka 日志
    local countNum=0
    local audioNum=0
    # 仅接收第三个参数到最后一个参数。如果仅接收从第一个到倒数第二个参数为LogArray=("${@:1:$#-1}")
    local LogArray=("${@:3}")
    # local logPathAndName="${pushKafkaLogArray[$path]}/push-kafka.log"
    # local statisticsStorage=y
    # local statisticsKeyWords="推送callId"

    for path in ${!LogArray[@]}
    do
        local logPathAndName="${LogArray[$path]}/${1}"
        local statisticsStorage=y
        local statisticsKeyWords="${2}"
        log_statistics $logPathAndName $statisticsStorage $statisticsKeyWords
    
        audioNum=$((audioNum + countNum))
    done
    echo ""
    echo "总数量是：$audioNum"
    echo ""
}

# 用于跨天的数解压和统计。需要三个参数$1,$2,$3（选填） 分别为跨天时间例如：20231201、解压方式，短信或者推送（选填）
untar() {
    # 解压响应日志
    #unzip -d $AUDIOlog_path/al_dm_${cross_time} $AUDIOlog_path/al_dm_${cross_time}_1.log.zip
    #gzip -d $smsLogPath/${cross_time}/* 

    # 如果是小程序就用 unzip 解压， 如果是短信和推送就用 gzip 解压
    if [ "$2" == "unzip" ]; then
        # 先判断文件是否存在
        if [ -e "${audioLogArray[0]}/al_dm_${1}_1.log.zip" ] && [ -e "${audioLogArray[0]}/al_dm_${1}_1.log.zip" ]; then
            
            for dir in ${audioLogArray[@]}
            do
                # 解压之前先创建目录
                # midir $AUDIOlog_path/al_dm_${cross_time}
                mkdir -p $dir/untar/al_dm_${1} $dir/untar/al_db_dm_${1}
                # 解压入库日志
                unzip -d $dir/untar/al_dm_${1} $dir/al_dm_${1}_1.log.zip
                # 往往压缩包比较大，所以多等一会
                sleep 30s
                unzip -d $dir/untar/al_db_dm_${1} $dir/al_db_dm_${1}_1.log.zip
                sleep 30s
            done
            echo ""
            echo "-----------打印${beforeTime}小程序日志开始-----------"
            echo ""
            # 统计前一天日志
            untarPathADBM="untar/al_db_dm_${beforeTime}/logs/al_db_dm_${beforeTime}_1.log"
            untarPathDM="untar/al_dm_${beforeTime}/logs/al_dm_${beforeTime}_1.log"
            logPrintAudio $untarPathADBM $untarPathDM
            echo ""
            echo "-----------打印${beforeTime}小程序日志结束-----------"
            echo ""

        else
            echo "${audioLogArray[0]}/al_dm_${1}_1.log.zip 或者 ${audioLogArray[0]}/al_dm_${1}_1.log.zip 不存在"
        fi

    # 解压短信或者推送
    elif [ "$2" == "gzip" ]; then
        if [ "$3" == "sms" ]; then
            if [ -d "${smsLogArray[0]}/${1}" ]; then

                for dir in ${smsLogArray[@]}
                do
                    gzip -d $dir/${1}/*
                    sleep 30s
                done

                echo ""
                echo "-----------打印${beforeTime}短信日志开始-----------"
                echo ""
                # 统计前一天短信日志
                untarPathPush="${beforeTime}/sms-management_${beforeTime}.1.log"
                statisticsKeyWords="短信发送成功"
                logPrintPushAndSms $untarPathPush $statisticsKeyWords "${smsLogArray[@]}"
                echo ""
                echo "-----------打印${beforeTime}短信日志结束-----------"
                echo ""

            else
                echo "${smsLogArray[0]}/${1} 没有该目录"
            fi
        elif [ "$3" == "push" ]; then
            if [ -d "${pushKafkaLogArray[0]}/${1}" ]; then
                for dir in ${pushKafkaLogArray[@]}
                do
                    gzip -d $dir/${1}/*
                    sleep 30s
                done

                echo ""
                echo "-----------打印${beforeTime}推送日志开始-----------"
                echo ""
                # 统计前一天推送日志
                untarPathPush="${beforeTime}/push-kafka_${beforeTime}.1.log"
                statisticsKeyWords="推送callId"
                logPrintPushAndSms $untarPathPush $statisticsKeyWords "${pushKafkaLogArray[@]}"
                echo ""
                echo "-----------打印${beforeTime}推送日志结束-----------"
                echo ""

            else
                echo "${pushKafkaLogArray[0]}/${1} 没有该目录"
            fi
        else
            echo "输入的服务名称有误，脚本退出"
            exit 1
        fi
    else
        echo "输入的解压类型有误，脚本退出"
        exit 1
    fi
}


for i in ${!thread[@]}
do
    # 清理小程序数据
    for k in ${!audioLogArray[@]}
    do
        echo "" > ${audioLogArray[$k]}/al_db_dm.log
        echo "" > ${audioLogArray[$k]}/al_dm.log
    done
    
    # 清理推送日志
    echo "" > $pushKafkaLogPath/push-kafka.log
    echo "" > $pushKafka_1_LogPath/push-kafka.log 
    
    # 清理短信日志
    echo "" > $smsLogPath/sms-management.log
    echo "" > $sms_1_LogPath/sms-management.logh

    # 清理jemter进程
    jmeter_PID=`ps -ef | grep $jmeterStartPath/jmeter.sh | grep -v grep | awk '{print $2}'`
        
    if [ -n "$jmeter_PID" ]; then
        ps -ef | grep jmeter | grep -v grep | awk '{print $2}' | xargs kill -9
    fi

    # 修改压测端口
    lastPort=`sed -n "54p" $jmeterCreatePath/$jmeterFile | awk -F ">" '{print $2}' | awk -F "<" '{print $1}'` 
    sed -i "54s/$lastPort/$stressProt/g" $jmeterCreatePath/$jmeterFile

    # 修改jmx文件并发数
    lastThread=`sed -n "21p" $jmeterCreatePath/$jmeterFile | awk -F ">" '{print $2}' | awk -F "<" '{print $1}'`
    sed -i "21s/$lastThread/${thread[$i]}/g" $jmeterCreatePath/$jmeterFile # 修改jmx文件ramp_time值
    lastRampTime=`sed -n "22p" $jmeterCreatePath/$jmeterFile | awk -F ">" '{print $2}' | awk -F "<" '{print $1}'`
    sed -i "22s/$lastRampTime/$ramp_time/g" $jmeterCreatePath/$jmeterFile

    # 修改jmx文件duration（非循环版本请注释掉）
    lastDuration=`sed -n "24p" $jmeterCreatePath/$jmeterFile | awk -F '>' '{print $2}' | awk -F '<' '{print $1}'`
    sed -i "24s/$lastDuration/$duration/g" $jmeterCreatePath/$jmeterFile

    # 修改monitorTool容器压测工具中的监控时间
    lastServertime=`sed -n "21p" $monitorCalc/calc_42_2.sh | awk -F '=' '{print $2}'`
    sed -i "21s/$lastServertime/$duration/g" $monitorCalc/calc_42_2.sh

    rm -rf $jmeterCreatePath/500.jtl
    #rm -rf $jmeterCreatePath/msgReport500

    current_time=`date "+%Y-%m-%d_%H_%M_%S"`
    echo "创建目录名称为：${logFile}/${current_time}"
    echo "并发数：${thread[$i]}"
    echo "jmeter执行时间为: $duration"

    mkdir $logFile/{$current_time}/
    mkdir $logFile/{$current_time}/log

    # 检测小程序、DM、NLU Prot是否存在
    for portSN in ${!Ports[@]}
    do
        portUsability=`ps -ef | grep -w ${Ports[$portSN]} | grep -v grep | awk '{print $2}'`
        if [ -z "$portUsability" ]; then
            echo "${Ports[$portSN]} 端口不存在"
            unset Ports[$portSN]
        else
            # 通过端口号获取docker容器名称,并生成数组
            dockerNames[$portSN]=`docker ps -a | grep -w "0.0.0.0:${Ports[$portSN]}" | awk '{print $NF}'`
        fi
    done
    echo "检测到小程序、NLU、DM 存在端口号为：${Ports[@]}"
    echo "检测到小程序、NLU、DM 容器名称为：${dockerNames[@]}"

    # 通过端口号获取程序PID
    for portSN in ${!Ports[@]}
    do
        PIDs[$portSN]=`ps -ef  |grep -w "host-port ${Ports[$portSN]}" | grep -v grep | awk '{print $2}'`
    done

    echo "检测到的小程序、NLU、DM 进程号为：${PIDs[@]}"
    
    echo "由于小程序不能直接通过端口号进程进行监控，所以重新更新"
 
    # 去掉所有的PID，检测容器中如果有audio、dm、nlu名称就将其PID去掉
    for ((i = ${#dockerNames[@]} - 1; i >= 0; i--)); do
        if [[ "${dockerNames[$i]}" == *"audiolistening"* ]]; then
            echo "将要移除的dockerName是: ${dockerNames[$i]}"
            audioPorts[$i]=${Ports[$i]}
            audioDockerNames[$i]=${dockerNames[$i]}
        elif [[ "${dockerNames[$i]}" == *"dm"* ]]; then
            echo "将要移除的dockerName是: ${dockerNames[$i]}"
            dmPorts[$i]=${Ports[$i]}
            dmDockerNames[$i]=${dockerNames[$i]}
        elif [[ "${dockerNames[$i]}" == *"nlu"* ]]; then
            echo "将要移除的dockerName是: ${dockerNames[$i]}"
            nluPorts[$i]=${Ports[$i]}
            nluDockerNames[$i]=${dockerNames[$i]}
        else
            newPIDs[$i]=${PIDs[$i]}
            newPorts[$i]=${Ports[$i]}
            newDockerNames[$i]=${dockerNames[$i]}
        fi
    done

    # 找到所有的小程序PID，并写入数组中
    audioPID=(`ps -ef  | grep -w "python audiolistening.py" | grep -v grep | awk '{print $2}'`)

    for element in "${audioPID[@]}"; do newPIDs+=("$element"); done
    for element in "${audioDockerNames[@]}"; do newDockerNames+=("$element"); done
    for element in "${audioPorts[@]}"; do newPorts+=("$element"); done

    # 找到所有DM PID, 并写入数组
    # dmPID=(`ps -ef | grep -v grep | grep -w "service/dm" | awk '{print $2}' `)
    
    # for element in "${dmPID[@]}"; do newPIDs+=("$element"); done
    # for element in "${dmDockerNames[@]}"; do newDockerNames+=("$element"); done
    # for element in "${dmPorts[@]}"; do newPorts+=("$element"); done
    
    # 找到所有NLU PID, 并写入数组
    #nluPID=(`ps -ef | grep -v grep | grep -w "/usr/local/pnlp/bin/NLUService.jar" | awk '{print $2}'`)

    #for element in "${nluPID[@]}"; do newPIDs+=("$element"); done
    #for element in "${nluDockerNames[@]}"; do newDockerNames+=("$element"); done
    #for element in "${nluPorts[@]}"; do newPorts+=("$element"); done

    # 将 push Kafka 和 redis proxy 写入 newDockerNames 和 newPIDs 中
    unset newDockerNames
    unset newPIDs
    unset newPorts

    newDockerNames+=(audiolistening audio_1 pushKafkaDocker_1 pushKafkaDocker_2 redisProxyDocker_1 redisProxyDocker_2 sms_1 sms_2 DM_1 DM_2 NLU_1 NLU_2 pbee_1 pbee_2)
    #newPIDs+=(1336747 1224001 3042595 3305174 142295 3951980 185837)
    newPorts+=(19042 19043 19811 19812 19809 19810 27426 27427 9024 9034 9007 9017 19003 19013)

    echo "更新后的容器名为: ${newDockerNames[@]}"
    echo "更新后的进程PID为: ${newPIDs[@]}"
    echo "更新后的端口号为: ${newPorts[@]}"

    # 启动容器监控程序
    #nohup sh $monitorCalc/calc_42.sh > $monitorCalc/monitorCalc_${thread[i]}.log 2>& 1 &

    # 获取jmeter压测日志文件stressTest文件中的开始时间
    stressStartTime=`cat stressTest.log | grep "Start" | head -1 | awk '{print $5,$6,$7,$8}'`
    echo "Jmeter开始执行时间 $stressStartTime"

    beforeTime=`date "+%Y%m%d"`

    nohup sh $jmeterStartPath/jmeter.sh -n -t $jmeterCreatePath/$jmeterFile -l $jmeterCreatePath/500.jtl -e -o $jmeterCreatePath/${current_time}_msgReport_${thread[i]} > $jmeterCreatePath/stressTest.log 2>& 1 &

    afterTime=`date "+%Y%m%d"`

    while true
    do
        jmeter_PID=`ps -ef | grep $jmeterPath/apache-jmeter-5.5/bin/jmeter.sh | grep -v grep | awk '{print $2}'`

        if [ -n "$jmeter_PID" ]; then

            # 监控所有程序的内存和CPU
            #for j in ${!newDockerNames[@]}
            #do
            #    top -n 1 -b | grep ${newPIDs[$j]} | awk '{print $10}' >> $logFile/{$current_time}/${newDockerNames[$j]}_Mem.txt
            #    top -n 1 -b | grep ${newPIDs[$j]} | awk '{print $9}' >> $logFile/{$current_time}/${newDockerNames[$j]}_Cpu.txt
            #done
            
            # 监控所有程序的连接数
            for dockerNameSN in ${!newDockerNames[@]}
            do
                netstat -antp | grep ${newPorts[$dockerNameSN]} | grep -v "LISTEN" | grep "ESTABLISHED" | wc -l >> $logFile/{$current_time}/${newDockerNames[$dockerNameSN]}_ESTABLISHED.txt
                netstat -antp | grep -v "LISTEN" | grep ${newPorts[$dockerNameSN]} | grep "TIME_WAIT" | wc -l >> $logFile/{$current_time}/${newDockerNames[$dockerNameSN]}_TIMEWAIT.txt
            done
 
            # top 总cpu
            top -n 1 -b | grep "%Cpu(s)" | awk '{print $2}' >> $logFile/{$current_time}/CPU.txt

            # top 总内存
            # top -n 1 -b | grep "KiB Mem"| awk '{print $7}' >> $logFile/{$current_time}/MEM.txt
            free -k | grep "Mem" | awk '{print $3}' | grep -o '^[0-9]\+' >> $logFile/{$current_time}/MEM.txt                

            top -b -n  1 | grep load | awk -F ':' '{print $5}' | awk '{print $2}' | awk -F ',' '{print $1}' >> $logFile/{$current_time}/loadAverage.txt

            sleep 30s

        else 
            # End_time=`date "+%Y-%m-%d_%H_%M_%S"`
            # 获取jmeter压测文件stressTest的结束时间
            sleep 0.5s
            stressEndTime=`cat stressTest.log | grep "Tidying up" | head -1 | awk '{print $5,$6,$7,$8}'`
            echo "$stressEndTime 监控结束，正在统计..."
            break
        fi
    done

    echo ""
    echo ""
    End_time=`date "+%Y-%m-%d_%H_%M_%S"`
    echo ""
    echo ""

    #cat /usr/local/audiolistening/logs/audiolistening_db_dm.log | grep -ai "error" >> $logFile/{$current_time}/log/error.log

    python3 calc.py $logFile/{$current_time}/ $jmeterCreatePath/${current_time}_msgReport_${thread[i]}/statistics.json

    cat $logFile/{$current_time}/result.txt

    echo "压测中会出现超时入库问题，所以等待5分钟后出统计数量"
    sleep 10s

    # 是否跨天需要解压并统计日志
    if [ "$beforeTime" != "$afterTime" ]; then
        # 解压小程序日志
        untar $beforeTime unzip
        # 解压推送日志
        untar $beforeTime gzip push
        # 解压短信日志
        untar $beforeTime gzip sms
    fi

    # 打印统计日志
    
    echo "" 
    echo "-----------打印${beforeTime}当天日志开始-----------"
    echo ""
    
    # 小程序日志
    echo "打印小程序日志"
    pathADBM="al_db_dm.log"
    pathADM="al_dm.log"
    logPrintAudio $pathADBM $pathADM

    # 打印推送日志
    echo "打印推送日志"
    untarPathPush="push-kafka.log"
    statisticsKeyWords="推送callId"
    logPrintPushAndSms $untarPathPush $statisticsKeyWords "${pushKafkaLogArray[@]}"

    # 打印短信日志
    echo "打印短信日志"
    untarPathPush="sms-management.log"
    statisticsKeyWords="推送callId"
    logPrintPushAndSms $untarPathPush $statisticsKeyWords "${smsLogArray[@]}"

    echo ""
    echo "-----------打印${beforeTime}当天日志结束-----------"
    echo ""
       
    #End_time=`date "+%Y-%m-%d_%H_%M_%S"`
    echo "结束时间为：$stressEndTime" 
    echo ""
    echo ""

done