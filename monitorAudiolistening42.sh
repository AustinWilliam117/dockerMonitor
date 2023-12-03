#!/bin/bash

# 小程序单实例版本，多实例执行会报错，原因是找不到对应的PID。
# 执行脚本可能造成grep多个PID情况，届时请核对该脚本grep的内容

#-----------------配置项-----------------
#jmeterFile=zyzx_audio_2_2.jmx                          #jmeter文件
jmeterFile=zyzx_yc_7.jmx                                #jmeter文件
#jmeterFile=zyzx_audio_nlp1.jmx                         #jmeter文件

thread=(20)                                             #并发数
cross_day=y                                             #是否跨天
# 获取跨天当前日期
cross_time=`date "+%Y%m%d"`

stressProt=19843                                        #压测端口 9800/9802 为单小程序, 9090为多实例

# 43200=12小时，21600=6小时，86400=24小时，259200=3天，14400=4小时
duration=43200                                          #循环持续时间（该版本为永久循环版本）

ramp_time=1                                             #花费多久的时间启动全部的线程

# 小程序端口号
#Ports=(9800 9802 9002 9001 19248 29001 29002 19249)
Ports=(19842)

basePath=/data/voice_bot_4.2
jmeterPath=/data/dengyuanjing/jmeter

# 容器监控脚本路径
monitorCalc=$jmeterPath/monitorTool

# 小程序路径
audioPath=$basePath/audiolistening_arm
audio1Path=$basePath/audiolistening_arm/audio_1

# 小程序日志路径
AUDIOlog_path=$basePath/audiolistening_arm/logs
AUDIO1log_path=$audio1Path/logs

# 短信日志路径
smsLogPath=$basePath/sms-management/logs
sms_1_LogPath=$basePath/sms-management/sms_1/logs

# 推送日志路径
pushKafkaLogPath=$basePath/push-kafka/pushKafka_1/logs
pushKafka_1_LogPath=$basePath/push-kafka/pushKafka_2/logs

# DMService日志流经
#DMSlog_path=/usr/local/pnlp/log/DMService/info.log

logFile=$jmeterPath/jmeterResult

# jmeter生成文件路径
jmeterCreatePath=$jmeterPath

# jmeter启动路径
jmeterStartPath=$jmeterPath/apache-jmeter-5.5/bin
# 注意：小程序连接数需要监控多个进程，目前只能主动填写
# python打印的并发数是一个占位值，可以填写真实的值
#-----------------配置项-----------------

# 用于跨天的数解压和统计。需要三个参数$1,$2 分别为日志路径、跨天时间、解压方式
untar() {
    # 解压响应日志
    #unzip -d $AUDIOlog_path/al_dm_${cross_time} $AUDIOlog_path/al_dm_${cross_time}_1.log.zip
    #gzip -d $smsLogPath/${cross_time}/* 

    # 如果是小程序就用 unzip 解压， 如果是短信和推送就用 gzip 解压
    if [ "$3" == "unzip" ]; then
        # 解压入库日志
        unzip -d $1/al_dm_${2} $1/al_db_dm_${2}_1.log.zip
        unzip -d $1/al_dm_${2} $1/al_db_dm_${2}_1.log.zip
    elif [ "$3" == "gzip" ]; then
        gzip -d $1/${2}/* 
        gzip -d $1/${2}/*
    else
        echo "输入的解压类型有误，脚本退出"
        exit 1
}

# 用于跨天的和统计。需要三个参数$1,$2,$3 分别为日志路径、跨天时间、入库字段
statistics() {
    # 统计小程序入库数量
    # echo -n "$AUDIOlog_path/${cross_time}/logs/$i 路径下错误数量为" && cat $AUDIOlog_path/${cross_time}/$i | grep "ERROR" | wc -l

    for i in `ls $1/al_dm_${2}`; do
        echo -n "$1/${2}/logs/$i 路径下错误数量为" && cat $1/${2}/$i | grep "ERROR" | wc -l
        echo ""
        echo -n "$1/${2}/logs/$i 路径下入库数量为" && cat $1/${2}/$i | grep "${3}" | wc -l
        echo ""
    done
}





for i in ${!thread[@]}
do
        # 清理小程序数据
        echo "" > $AUDIOlog_path/al_db_dm.log
        echo "" > $AUDIO1log_path/al_db_dm.log
        echo "" > $pushKafkaLogPath/push-kafka.log
        echo "" > $pushKafka_1_LogPath/push-kafka.log 
        echo "" > $AUDIOlog_path/al_dm.log
        echo "" > $AUDIO1log_path/al_dm.log
        # 清理短信日志
        echo "" > $smsLogPath/sms-management.log
        echo "" > $sms_1_LogPath/sms-management.log
        # 清理DMService 日志
        #echo > $DMSlog_path

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
        # nohup sh $monitorCalc/calc_42.sh > $monitorCalc/monitorCalc_${thread[i]}.log 2>& 1 &

        # 获取jmeter压测日志文件stressTest文件中的开始时间
        stressStartTime=`cat stressTest.log | grep "Start" | head -1 | awk '{print $5,$6,$7,$8}'`
        echo "Jmeter开始执行时间 $stressStartTime"


        nohup sh $jmeterStartPath/jmeter.sh -n -t $jmeterCreatePath/$jmeterFile -l $jmeterCreatePath/500.jtl -e -o $jmeterCreatePath/${current_time}_msgReport_${thread[i]} > $jmeterCreatePath/stressTest.log 2>& 1 &

        while true
        do

            jmeter_PID=`ps -ef | grep /data/dengyuanjing/jmeter/apache-jmeter-5.5/bin/jmeter.sh | grep -v grep | awk '{print $2}'`

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
                #top -n 1 -b | grep "KiB Mem"| awk '{print $7}' >> $logFile/{$current_time}/MEM.txt
                free -k | grep "Mem" | awk '{print $3}' | grep -o '^[0-9]\+' >> $logFile/{$current_time}/MEM.txt                

                top -b -n  1 | grep load | awk -F ':' '{print $5}' | awk '{print $2}' | awk -F ',' '{print $1}' >> $logFile/{$current_time}/loadAverage.txt

                sleep 5m

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
        sleep 2m

        # 判断是否跨天，如果跨天了解压前一天的日志并统计
        if [ "$cross_day" == "y" ]
        then
                # 解压小程序前，注意日志大小一定要设置100G以上
                midir $AUDIOlog_path/al_dm_${cross_time}
                midir $AUDIO1log_path/al_dm_${cross_time}
                # 解压响应日志
                unzip -d $AUDIOlog_path/al_dm_${cross_time} $AUDIOlog_path/al_dm_${cross_time}_1.log.zip
                unzip -d $AUDIO1log_path/al_dm_${cross_time} $AUDIOlog_path/al_dm_${cross_time}_1.log.zip

                # 解压入库日志
                unzip -d $AUDIOlog_path/al_dm_${cross_time} $AUDIOlog_path/al_db_dm_${cross_time}_1.log.zip
                unzip -d $AUDIO1log_path/al_dm_${cross_time} $AUDIOlog_path/al_db_dm_${cross_time}_1.log.zip

                # 统计小程序入库数量
                for i in `ls $AUDIOlog_path/al_dm_${cross_time}`; do
                    echo -n "$AUDIOlog_path/${cross_time}/logs/$i 路径下错误数量为" && cat $AUDIOlog_path/${cross_time}/$i | grep "ERROR" | wc -l
                    echo ""
                    echo -n "$AUDIOlog_path/${cross_time}/logs/$i 路径下入库数量为" && cat $AUDIOlog_path/${cross_time}/$i | grep "短信发送成功" | wc -l
                    echo ""
                done

                for i in `ls $AUDIO1log_path/al_dm_${cross_time}`; do
                    echo -n "$AUDIO1log_path/${cross_time}/logs/$i 路径下错误数量为" && cat $AUDIO1log_path/${cross_time}/$i | grep "ERROR" | wc -l
                    echo ""
                    echo -n "$AUDIO1log_path/${cross_time}/logs/$i 路径下入库数量为" && cat $AUDIO1log_path/${cross_time}/$i | grep "短信发送成功" | wc -l
                    echo ""
                done

                # 解压短信前，日志大小一定要设置100G以上
                gzip -d $smsLogPath/${cross_time}/* 
                gzip -d $sms_1_LogPath/${cross_time}/*

                # 统计短信入库数量 和 是否有 Error
                for i in `ls $smsLogPath/${cross_time}`; do
                    echo -n "$smsLogPath/${cross_time}/$i 路径下错误数量为" && cat $smsLogPath/${cross_time}/$i | grep "ERROR" | wc -l
                    echo ""
                    echo -n "$smsLogPath/${cross_time}/$i 路径下入库数量为" && cat $smsLogPath/${cross_time}/$i | grep "短信发送成功" | wc -l
                    echo ""
                done

                for i in `ls $sms_1_LogPath/${cross_time}`; do
                    echo -n "$sms_1_LogPath/${cross_time}/$i 路径下错误数量为" && cat $sms_1_LogPath/${cross_time}/$i | grep "ERROR" | wc -l
                    echo ""
                    echo -n "$sms_1_LogPath/${cross_time}/$i 路径下入库数量为" && cat $sms_1_LogPath/${cross_time}/$i | grep "短信发送成功" | wc -l
                    echo ""
                done

                # 解压计费上传前，日志大小一定要设置100G以上
                gzip -d $pushKafkaLogPath/${cross_time}/* 
                gzip -d $pushKafka_1_LogPath/${cross_time}/*

                # 统计计费入库数量
                for i in `ls $pushKafkaLogPath/${cross_time}`; do
                    echo -n "$pushKafkaLogPath/${cross_time}/$i 路径下错误数量为" && cat $pushKafkaLogPath/${cross_time}/$i | grep "ERROR" | wc -l
                    echo ""
                    echo -n "$pushKafkaLogPath/${cross_time}/$i 路径下入库数量为" && cat $pushKafkaLogPath/${cross_time}/$i | grep "推送callId" | wc -l
                    echo ""
                done

                for i in `ls $pushKafka_1_LogPath/${cross_time}`; do
                    echo -n "$pushKafka_1_LogPath/${cross_time}/$i 路径下错误数量为" && cat $pushKafka_1_LogPath/${cross_time}/$i | grep "ERROR" | wc -l
                    echo ""
                    echo -n "$pushKafka_1_LogPath/${cross_time}/$i 路径下入库数量为" && cat $pushKafka_1_LogPath/${cross_time}/$i | grep "推送callId" | wc -l
                    echo ""
                done

        fi

        #cp $AUDIOlog_path/al_push_dm.log $AUDIOlog_path/al_push_dm.log_{$current_time}
        cp $AUDIOlog_path/al_db_dm.log $AUDIOlog_path/al_db_dm.log_{$current_time}_bak
        cp $AUDIOlog_path/al_dm.log $AUDIOlog_path/al_dm.log_{$current_time}_bak
        echo -n "audioListening al_db_dm.log Error 数量是: " && cat $AUDIOlog_path/al_db_dm.log_{$current_time}_bak | grep -ai "error" | wc -l
        echo -n "audioListening al_dm.log Error 数量是: " && cat $AUDIOlog_path/al_dm.log_{$current_time}_bak | grep "ERROR" | wc -l
        audioNum=`cat $AUDIOlog_path/al_db_dm.log_{$current_time}_bak | grep "入库完成" | wc -l`
        echo -n "audioListening 入库数量是: " && echo "$audioNum"
        echo -n "audioListening 最后一条数据入库时间是: " && cat $AUDIOlog_path/al_db_dm.log_{$current_time}_bak | grep "整通通话入库完成" | tail -1 | awk '{print $1,$2}'

        cp $AUDIO1log_path/al_db_dm.log $AUDIO1log_path/al_db_dm.log_{$current_time}_bak
        cp $AUDIO1log_path/al_dm.log $AUDIO1log_path/al_dm.log_{$current_time}_bak
        echo -n "audioListening_1 al_db_dm.log Error 数量是: " && cat $AUDIO1log_path/al_db_dm.log_{$current_time}_bak | grep -ai "error" | wc -l
        echo -n "audioListening_1 al_dm.log Error 数量是: " && cat $AUDIO1log_path/al_dm.log_{$current_time}_bak | grep "ERROR" | wc -l
        audio1Num=`cat $AUDIO1log_path/al_db_dm.log_{$current_time}_bak | grep "入库完成" | wc -l`
        echo -n "audioListening_1 入库数量是：" && echo "$audio1Num"
        echo -n "audioListening_1 最后一条数据入库时间是: " && cat $AUDIO1log_path/al_db_dm.log_{$current_time}_bak | grep "整通通话入库完成" | tail -1 | awk '{print $1,$2}'

        echo ""
        echo "小程序入库总数量是：$(($audioNum+$audio1Num))"
        echo ""
       
        cp $smsLogPath/sms-management.log $smsLogPath/sms-management.log_{$current_time}_bak
        echo -n "sms_1 Error 数量是: " && cat $smsLogPath/sms-management.log_{$current_time}_bak | grep -ai "error" | wc -l
        # 由于短信日志过大会切分日志，测试请将默认100M改大
        sms_1=`cat $smsLogPath/sms-management.log_{$current_time}_bak | grep "短信发送成功" | wc -l`
        echo -n "sms_1 入库数量是: " && echo "$sms_1"
        echo -n "sms_1 最后一条数据的入库时间是: " && cat $smsLogPath/sms-management.log_{$current_time}_bak | grep "短信发送成功" | tail -1 | awk -F '[' '{print $1,$2}' | awk -F ']' '{print $1,$2}'

        cp $sms_1_LogPath/sms-management.log $sms_1_LogPath/sms-management.log_{$current_time}_bak
        echo -n "sms_2 Error 数量是: " && cat $sms_1_LogPath/sms-management.log_{$current_time}_bak | grep -ai "error" | wc -l
        # 由于短信日志过大会切分日志，测试请将默认100M改大
        sms_2=`cat $sms_1_LogPath/sms-management.log_{$current_time}_bak | grep "短信发送成功" | wc -l`
        echo -n "sms_2 入库数量是: " && echo "$sms_2"
        echo -n "sms_2 最后一条数据的入库时间是: " && cat $sms_1_LogPath/sms-management.log_{$current_time}_bak | grep "短信发送成功" | tail -1 | awk -F '[' '{print $1,$2}' | awk -F ']' '{print $1,$2}'

        echo ""
        echo "短信入库总数量是：$(($sms_1+$sms_2))"
        echo ""

        cp $pushKafkaLogPath/push-kafka.log $pushKafkaLogPath/push-kafka.log_{$current_time}_bak
        echo -n "pushKafka_1 Error 数量是: " && cat $pushKafkaLogPath/push-kafka.log_{$current_time}_bak | grep -ai "error" | wc -l
        # 由于pushKafka日志过大会切分日志，测试请将默认100M改大
        pushKfk1=`cat $pushKafkaLogPath/push-kafka.log_{$current_time}_bak | grep "推送callId" | wc -l`
        echo -n "pushKafka_1 推送数量是: " && echo "$pushKfk1"
        echo -n "pushKafka_1 最后一条数据的入库时间是: " && cat $pushKafkaLogPath/push-kafka.log_{$current_time}_bak | grep "推送callId" | tail -1 | awk -F '[' '{print $1,$2}' | awk -F ']' '{print $1,$2}'

        cp $pushKafka_1_LogPath/push-kafka.log $pushKafka_1_LogPath/push-kafka.log_{$current_time}_bak
        echo -n "pushKafka_2 Error 数量是: " && cat $pushKafka_1_LogPath/push-kafka.log_{$current_time}_bak | grep -ai "error" | wc -l
        # 由于pushKafka日志过大会切分日志，测试请将默认100M改大
        pushKfk2=`cat $pushKafka_1_LogPath/push-kafka.log_{$current_time}_bak | grep "推送callId" | wc -l`
        echo -n "pushKafka_2 推送数量是: " && echo "$pushKfk2"
        echo -n "pushKafka_2 最后一条数据的入库时间是: " && cat $pushKafka_1_LogPath/push-kafka.log_{$current_time}_bak | grep "推送callId" | tail -1 | awk -F '[' '{print $1,$2}' | awk -F ']' '{print $1,$2}'

        echo ""
        echo "推送总数量是：$(($pushKfk1+$pushKfk2))"
        echo ""

        #cat $logFile/{$current_time}/log/error.log | wc -l

        #cat $jmeterCreatePath/${current_time}_msgReport_${i} 
        echo ""

        #echo "推送的数量是"
        #cat $AUDIOlog_path/al_push_dm.log | grep "请求body" | wc -l

        #echo ""

        #End_time=`date "+%Y-%m-%d_%H_%M_%S"`
        echo "结束时间为：$stressEndTime" 
        echo ""
        echo ""

done
