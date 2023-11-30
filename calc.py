import math,sys,os,json

"""
    字体颜色
"""
class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m '
"""
    初始化日志
"""
def createLog():
    with open(resultPath,'a+',encoding='utf-8') as f:
        #f.write('并发次数为：'+str(thread_num))
        f.write("\n======================================================\n")
        f.write("%s\t%s\t%s\t%s\t%5s\t%5s\t%5s\n" %("type","Max","Min","Avg","PCT90","PCT95","PCT99"))

"""
    获取路径所有文件
"""
def getFiles(PATH):
    for root, dirs, files in os.walk(PATH):
        return files

"""
    运算90、95、99百分位
    1.接收要统计的项目名称，接收完整的路径，接收排序好的数组
"""
def calc(proName,array):
    percent1 = 99
    percent2 = 95
    percent3 = 90
    a1 = percent1/100
    a2 = percent2/100
    a3 = percent3/100

    num_count = len(array)
    if proName == 'MEM':
        array1 = []
        array1 = array
        array = []
        for i in array1:
            array.append(i/1024/1024)
        num_count = len(array)   

    # 最大值、最小值、平均值
    maxValue = round(array[-1],2)
    mixValue = round(array[0],2)
    averageValue = round(sum(array)/len(array),2)

    # 90、95、99%
    if math.ceil(num_count*a1) == num_count:
        percent_99 = round(array[num_count-1],2)
    else:
        percent_99 = round(array[math.ceil(num_count*a1)],2)
    if math.ceil(num_count*a2) == num_count:
        percent_95 = round(array[num_count-1],2)
    else:
        percent_95 = round(array[math.ceil(num_count*a2)],2)
    if math.ceil(num_count*a3) == num_count:
        percent_90 = round(array[num_count-1],2)
    else:
        percent_90 = round(array[math.ceil(num_count*a3)],2)

    # 将值存入字典
    resultDict[proName] = [maxValue, mixValue, averageValue, percent_90, percent_95, percent_99]

    #print("路径为："+txtPath)
   # with open(resultPath,'a+',encoding='utf-8') as f:
   #     f.write("%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\n" %(proName,maxValue,mixValue,averageValue,percent_90,percent_95,percent_99))
    print("%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\n" %(proName,maxValue,mixValue,averageValue,percent_90,percent_95,percent_99))

    return resultDict

"""
    这段代码后期可以细化，重复代码可拿出来单写，return array

    1.判断是buff/resp
    2.读取buff/resp路径下的监控日志，排序后调用calc函数
"""

def solve():
    for i in fileList:
        array = []
        logPath = PATH + i
        # 读取监控日志内容,并写入列表
        if os.path.getsize(logPath) == 0:
            for k in range(6):
                array.append(float(0))
            array.sort()
            proName = i.split(".")[0]
            calc(proName,array)
        else:
            with open(logPath,'r+',encoding='utf-8') as f:
                for line in f.readlines():
                    if len(line) >= 15:
                        print(bcolors.WARNING+"WARNING"+bcolors.END+logPath+logPath+"检测结果大于15位数，被抛弃")
                        continue
                    try:
                        array.append(float(line))
                    except:
                        print(bcolors.FAIL+"ERROR"+bcolors.END+logPath+"该值有问题，",line)
            array.sort()
            proName = i.split(".")[0]
            calc(proName,array)
            
"""
    打印想要的结果
"""
def printData():
    """
        [[[项目index],[监控值index]],[[项目index],[监控值index]], ...]
        需要显示的数据 
        0 最大值
        1 最小值
        2 平均值
        3 90%
        4 95%
        5 99%
    """
    # values = [[Pdist['AudioListenCpu'][0], Pdist['AudioListenCpu'][1]], [Pdist['AudioListenMem'][1], Pdist['AudioListenMem'][2]]]
    # print(*values)
    
    print('===============================================\n')
        
    resultList = []
    
    #keys = ['CPU','MEM','AudioLinstening_TIMEWAIT','Audio_ESTABLISHED','AudioListenCpu','DMcpu','DMmem','DM_TIMEWAIT','DM_ESTABLISHED','NLUcpu','NLUmem','NLU_TIMEWAIT','NLU_ESTABLISHED']
    #indexes = [[4,0], [0], [0,2], [0,2], [5], [4], [4], [5], [5], [4], [4], [5], [5]]
    #keys = ['CPU','MEM','AudioLinstening_TIMEWAIT','Audio_ESTABLISHED','AudioListenCpu','AudioListenMem']
    #indexes = [[0,4], [0,4], [0,2], [0,2], [4,0], [4,0]]
    keys = ['CPU','MEM']
    indexes = [[0,4], [0,4]]
    #print(resultDict)
    result = []
    for key, idx in zip(keys, indexes):
        print(f"{key},{idx}",end="\t")
        result.extend( (str(resultDict[key][i]) for i in idx))

    print()

    for i in result:
        print(i,end="\t")
        resultList.append(i)
    print()
    
    return resultList

"""
    打印jmeter报告
"""
def printJmeterReslut(jmeterPath):


    with open(jmeterPath,'r+',encoding='utf-8') as statistics_F, open(resultPath,'r+',encoding='utf-8') as f:
        txt = json.loads(''.join(statistics_F.readlines()))
        #print(type(txt))
        try:
            # 写入返回的列表数据
            f.write('\n')           
            f.write(resultList)
            f.write('\n')           
            f.write('\n')           
            f.write("End总请求\tEnd总请求失败\tanswerCall总请求：\n")
            print("End总请求\tEnd总请求失败\tanswerCall总请求：")
            f.write(str(txt['End']['sampleCount']) + '\t' + str(txt['End']['errorCount']) + 
                    '\t' + str(txt['answerCall']['sampleCount']) + '\n')
            print(str(txt['End']['sampleCount']) + '\t' + str(txt['End']['errorCount']) + '\t' + str(txt['answerCall']['sampleCount']) + '\n')
        except: 
            f.write("\t未在json中找到End\n")
            #print("未在json中找到End")
        try:
            f.write("answerCall总请求\tTotle中请求总数\t失败数\t吞吐量\t响应时间平均值\t中位数\t响应时间MAX\t响应时间MIN\t响应时间90%\t响应时间95%\t响应时间99%\t错误率\n\n")
            #print("Totle中请求总数\t失败数\t响应时间平均值\t响应时间MAX\t响应时间MIN\t响应时间90%\t响应时间95%\t响应时间99%\t错误率)jj
            f.write(str(txt['answerCall']['sampleCount'])+ '\t' + str(txt['Total']['sampleCount']) +
                    '\t' + str(txt['Total']['errorCount']) + 
                    '\t' + str(int(txt['Total']['throughput'])-int(txt['生成手机号']['throughput'])) +
                    '\t' + str(txt['Total']['meanResTime']) +
                    '\t' + str(txt['Total']['medianResTime']) + '\t' + str(txt['Total']['minResTime']) + 
                    '\t' + str(txt['Total']['maxResTime']) + '\t' + str(txt['Total']['pct1ResTime']) + 
                    '\t' + str(txt['Total']['pct2ResTime']) + '\t' + str(txt['Total']['pct3ResTime']) + 
                    '\t' + str(txt['Total']['errorPct']) + '\n\n')
            f.write("===============================================\n")

        except:
            f.write("\t未在json中找到Totle\n")
            #print("未在json中找到Totle")


    #resultList = printData()
 
if __name__ == '__main__':
    PATH = sys.argv[1]
    jmeterPath = sys.argv[2]
    #thread_num = sys.argv[2]
    resultPath = PATH + 'result.txt'
    #fileList = ["AudioListenCpu.txt","AudioListenMem.txt","DMmem.txt","DMcpu.txt","DMthreadCount.txt","NLUthreadCount.txt","AudioLinstening.txt"]

    # 
    fileList = getFiles(PATH)
    if "result.txt" in fileList:
        fileList.remove("result.txt")
       
    # 创建以文件名为键的字典
    key = []
    resultDict = {}
    for i in fileList:
        key.append(i.split(".")[0])
    resultDict = dict.fromkeys(key)

    # 执行程序
    createLog()
    printJmeterReslut(jmeterPath)
    solve()
