from curses.ascii import isspace
import math
import re,os
import sys


def write_calc():
    txtPath = PATH + 'calc.txt'
    #print("路径为："+txtPath)
    with open(txtPath,'a+',encoding='utf-8') as f:
        f.write(server+'\n')
        f.write("======================================================\n")
        f.write("%s\t%s\t%s\t%s\t%5s\t%5s\t%5s\n" %("type","Max","Min","Avg","PCT90","PCT95","PCT99"))
        #f.write("type\tMax\tMin\tAvg\tPCT90\tPCT95\tPCT99\n")


"""
    1.calc 函数接收两个参数，一个是shell过滤后的值的单位，一个是shell过滤后的数组
    2.calc 仅接受排序后的数组
"""
def calc(unit,array,server,listName):
    
    # 90/95/99百分率计算
    percent1 = 99
    percent2 = 95
    percent3 = 90
    a1 = percent1/100
    a2 = percent2/100
    a3 = percent3/100

    num_count = len(array)

    # 最大值、最小值、平均值
    maxValue = array[-1]
    mixValue = array[0]
    averageValue = sum(array)/len(array)

    # 90、95、99%
    if math.ceil(num_count*a1) == num_count:
        percent_99 = array[num_count-1]
    else:
        percent_99 = array[math.ceil(num_count*a1)]
    if math.ceil(num_count*a2) == num_count:
        percent_95 = array[num_count-1]
    else:
        percent_95 = array[math.ceil(num_count*a2)]
    if math.ceil(num_count*a3) == num_count:
        percent_90 = array[num_count-1]
    else:
        percent_90 = array[math.ceil(num_count*a3)]

    #print("PATH:",PATH)
    txtPath = PATH + 'calc.txt'
    #print("路径为："+txtPath)
    with open(txtPath,'a+',encoding='utf-8') as f:
        f.write("%s%s%s%s\t %.2f %.2f %.2f %.2f %.2f %.2f\n" %(listName,"(",unit,")",maxValue,mixValue,averageValue,percent_90,percent_95,percent_99))

# 将两个列表的值改写到的文件中
def save_txt(list1, list2, save_path):
    if os.path.isfile(save_path):
        save_path_new = save_path+'_old'
        #print(save_path_new)
        os.rename(save_path,save_path_new)
    with open(save_path, "a") as f:
        for i in range(len(list1)):
            f.write('{}{}\n'.format(list1[i], list2[i]))

# docker中网络IO/读写IO单位不同转换，未涉及内存单位问题
def transformation(i,unitList):
    temporaryList = []
    with open(i,'r+',encoding='utf-8') as f:
        for line in f.readlines():
            if line.isspace():
                continue
            else:
                pattern_value = re.findall(r'\d+',line)
                num = pattern_value[0]
                temporaryList.append(float(num))
    # print(temporaryList)
    # 逐一比对单位，将不同的单位统一修改成相同单位
    # print("unitList",unitList)
    for k in range(0,len(unitList)):
        for j in range(k+1,len(unitList)):
            if unitList[k] == unitList[j]:
                continue
            else:
                # B kB MB GB
                if unitList[k] == "MB" and unitList[j] == "GB":
                    temporaryList[j] = temporaryList[j] * 1000
                    unitList[j] = "MB"
                elif unitList[k] == "MB" and unitList[j] == "kB":
                    temporaryList[j] = temporaryList[j] / 1000
                    unitList[j] = "MB"
                elif unitList[k] == "MB" and unitList[j] == "B":
                    temporaryList[j] = temporaryList[j] / 1000 / 1000
                    unitList[j] = "MB"
                elif unitList[k] == "kB" and unitList[j] == "MB":
                    temporaryList[j] = temporaryList[j] * 1000
                    unitList[j] = "kB"
                elif unitList[k] == "kB" and unitList[j] == "GB":
                    temporaryList[j] = temporaryList[j] * 1000 * 1000
                    unitList[j] = "kB"
                elif unitList[k] == "kB" and unitList[j] == "B":
                    temporaryList[j] = temporaryList[j] / 1000
                    unitList[j] = "kB"
                elif unitList[k] == "GB" and unitList[j] == "MB":
                    temporaryList[j] = temporaryList[j] / 1000
                    unitList[j] = "GB"
                elif unitList[k] == "GB" and unitList[j] == "kB":
                    temporaryList[j] = temporaryList[j] / 1000 / 1000
                    unitList[j] = "GB"
                elif unitList[k] == "GB" and unitList[j] == "B":
                    temporaryList[j] = temporaryList[j] / 1000 / 1000 / 1000
                    unitList[j] = "GB"
                elif unitList[k] == "B" and unitList[j] == "kB":
                    temporaryList[j] = temporaryList[j] * 1000
                    unitList[j] = "B"
                elif unitList[k] == "B" and unitList[j] == "MB":
                    temporaryList[j] = temporaryList[j] * 1000 * 1000
                    unitList[j] = "B"
                elif unitList[k] == "B" and unitList[j] == "GB":
                    temporaryList[j] = temporaryList[j] * 1000 * 1000 * 1000
                    unitList[j] = "B"

                # B KiB MiB GiB
                elif unitList[k] == "MiB" and unitList[j] == "GiB":
                    temporaryList[j] = temporaryList[j] * 1024
                    unitList[j] = "MiB"
                elif unitList[k] == "MiB" and unitList[j] == "KiB":
                    temporaryList[j] = temporaryList[j] / 1024
                    unitList[j] = "MiB"
                elif unitList[k] == "MiB" and unitList[j] == "B":
                    temporaryList[j] = temporaryList[j] / 1024 / 1024
                    unitList[j] = "MiB"
                elif unitList[k] == "KiB" and unitList[j] == "MiB":
                    temporaryList[j] = temporaryList[j] * 1024
                    unitList[j] = "KiB"
                elif unitList[k] == "KiB" and unitList[j] == "GiB":
                    temporaryList[j] = temporaryList[j] * 1024 * 1024
                    unitList[j] = "KiB"
                elif unitList[k] == "KiB" and unitList[j] == "B":
                    temporaryList[j] = temporaryList[j] / 1024
                    unitList[j] = "KiB"
                elif unitList[k] == "GiB" and unitList[j] == "MiB":
                    temporaryList[j] = temporaryList[j] / 1024
                    unitList[j] = "GiB"
                elif unitList[k] == "GiB" and unitList[j] == "kiB":
                    temporaryList[j] = temporaryList[j] / 1024 / 1024
                    unitList[j] = "GiB"
                elif unitList[k] == "GiB" and unitList[j] == "B":
                    temporaryList[j] = temporaryList[j] / 1024 / 1024 / 1024
                    unitList[j] = "GiB"
                elif unitList[k] == "B" and unitList[j] == "KiB":
                    temporaryList[j] = temporaryList[j] * 1024
                    unitList[j] = "B"
                elif unitList[k] == "B" and unitList[j] == "MiB":
                    temporaryList[j] = temporaryList[j] * 1024 * 1024
                    unitList[j] = "B"
                elif unitList[k] == "B" and unitList[j] == "GiB":
                    temporaryList[j] = temporaryList[j] * 1024 * 1024 * 1024
                    unitList[j] = "B"
        break        
    save_txt(temporaryList,unitList,i)

"""
    用于分离出unit

    用于读取数据，并创建列表，将其送入calc计算最大、最小值
    1.循环列表
    2.打印要计算的列表的名称，如：CPU_Usage、MEM_Usage
    3.读取该路径文件
    4.按照read_file()分离出来的unit，添加数组元素
    5.送入calc()计算
"""
def read_file():
    # 分割出每个log中的单位
    for i in arrayPath:
        with open(i,'r+',encoding='utf-8') as f:
            # 读取第一行
            firstLine = f.readline()
            # 正则匹配非数字的最后一位，即单位
            pattern_value = re.findall(r'\D+',firstLine)
            unit = pattern_value[-1]
            unit = unit.split()[0]
        #print('-------------------------------------单位为：'+unit)
        # 读取每一行，将所有单位分离出来，并写入unitList中
        unitList = []
        with open(i,'r+',encoding='utf-8') as f:
            # 读取每一行
            for line in f.readlines():
                if line.isspace():
                    continue
                else:
                    pattern_value = re.findall(r'\D+',line)
                    unit = pattern_value[-1]
                    unit = unit.split()[0]
                    unitList.append(unit)

        # 检查列表中所有元素是否相同
        isSame = unitList.count(unitList[0]) == len(unitList)
        if(isSame):
            #print("列表中所有元素相同")
            pass
        else:
            print(i+"列表中有元素不相同")
            print("不相同的单位有",set(unitList))
            # 读取文件，将所有的值都写入列表
            transformation(i,unitList)

        # 用于读取数据，并创建列表，将其送入calc计算最大、最小值
        listName = i.split('/')[-1]
        listName = listName.split('.')[0]
        #print()
        #print(listName)
        #print(type(listName))
        array = []
        unit = unitList[0]
        with open(i,'r+',encoding='utf-8') as f:
            for line in f.readlines():
                if line.isspace():
                    continue
                else:
                    lineValue = line.split(unit)[0]
                    try:
                        array.append(float(lineValue))
                    except ValueError:
                        print(server+" "+i+"加入列表进行计算的值格式有误! line为："+str(line)+"lineValue为："+str(lineValue)+"unit为："+str(unit))
        array.sort()
        calc(unit,array,server,listName)
    
if __name__ == '__main__':
    """
    设置读取的文本路径
    1.cpuUsagePath
    2.memUsagePath
    3.memRatePath
    4.netInputPath
    5.netOutputPath
    6.blockInputPath
    7.blockOutputPath
    """

    PATH = sys.argv[1]
    server = sys.argv[2]
    #print("============================================================")
    #print(PATH)

    write_calc()
    if server == "freeSwitch":
        cpuUsagePath = PATH+'fscpu.txt'
        memUsagePath = PATH+'fsmem.txt'
        arrayPath = [cpuUsagePath, memUsagePath]
        unit="%"
        for i in arrayPath:
            array = []
            listName = i.split('/')[-1]
            listName = listName.split('.')[0]
            with open(i,'r+',encoding='utf-8') as f:
                for line in f.readlines():
                    try:
                        array.append(float(line))
                    except ValueError:
                        print(i,"中有错误数据，请查看")
            array.sort()
            calc(unit,array,server,listName)
    else:
        cpuUsagePath = PATH+'CPU_Usage.log'
        memUsagePath = PATH+'MEM_Usage.log'
        memRatePath = PATH+'MEM_Rate.log'
        netInputPath = PATH+'NET_input.log'
        netOutputPath = PATH+'NET_output.log'
        blockInputPath = PATH+'Block_input.log'
        blockOutputPath = PATH+'Block_output.log'
        arrayPath = [cpuUsagePath, memUsagePath, memRatePath, netInputPath, netOutputPath, blockInputPath, blockOutputPath]
        # 函数调用
        read_file()
