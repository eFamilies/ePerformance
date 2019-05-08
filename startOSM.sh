#!/bin/sh
#Lever      modified 2013/8/21 10:02:27

interval=$1
if [ "$interval" = "" ]
then
  interval=5
fi
keepPeriod=30

outDir=./output
runLogFile=./log/alert_OSM.log
archiveDir=./archive
mkdir -p $archiveDir

writeLog()
{
  local l_time=`date "+%Y/%m/%d %H:%M:%S"`
  local l_hostName=`hostname`

  echo "[$l_hostName] [${l_time}] [$$] $* " >> $runLogFile
}

#设置时间为24小时制
export LANG=c

writeLog "startOSM begin..."
sleep 1

pID="t_stat_"
pName="`basename $0`"
######################################################################
# First check to see if startOSM is already running
######################################################################
ps -ef | grep $pID  | grep -v grep > /dev/null
if [ $? -eq 0 ]
then
  echo "An $pName process has been detected."
  echo "Please stop it before starting a new $pName  process."
  exit
fi

colList="start,time,user,pid,ppid,stat,psr,%cpu,rss,vsz,%mem,tt,wchan,command"
while [ 1 ]
do
  TODAY=`date "+%Y%m%d"`
  OUTPUT_DIR=$outDir/$TODAY
  mkdir -p $OUTPUT_DIR

  CURRENT_TIME=`date "+%Y-%m-%d %H:%M:%S"`
  CURRENT_TIME_S=`date -d "$CURRENT_TIME" +%s`
  TOMORROW="`date +%Y-%m-%d -d "1 day"` 00:00:00"
  TOMORROW_S=`date -d "$TOMORROW" +%s`
  loop_count=`expr \( $TOMORROW_S - $CURRENT_TIME_S \) \/ $interval`

  pre_nice="nice -n 19 "
  ### (1) gather os information
  snapshot_File=${OUTPUT_DIR}/t_stat_sar.snap
  stat_cmd="${pre_nice} sar -A -o $snapshot_File $interval $loop_count"
  writeLog "$stat_cmd ..."
  nohup $stat_cmd & 
  
  pidstat >/dev/null 2>&1
  if [ $? -eq 0 ]
  then
    ### (t_pid_cpu) 可以关闭，考虑从ps中获取
    snapshot_File=${OUTPUT_DIR}/t_pid_cpu.snap
    stat_cmd="${pre_nice} pidstat -ul  $interval $loop_count "
    writeLog "$stat_cmd ..."
    nohup $stat_cmd >> $snapshot_File 2>&1 & 
    
    ### (t_pid_disk)
    snapshot_File=${OUTPUT_DIR}/t_pid_disk.snap
    stat_cmd="${pre_nice} pidstat -dl  $interval $loop_count"
    writeLog "$stat_cmd ..."
    nohup $stat_cmd >> $snapshot_File 2>&1 & 
    
    ### (t_pid_mem)  可以关闭，考虑从ps中获取
    snapshot_File=${OUTPUT_DIR}/t_pid_mem.snap
    stat_cmd="${pre_nice} pidstat -rl  $interval $loop_count"
    writeLog "$stat_cmd ..."
    nohup $stat_cmd >> $snapshot_File 2>&1 & 
    
    ### (t_pid_switch)
    snapshot_File=${OUTPUT_DIR}/t_pid_switch.snap
    stat_cmd="${pre_nice} pidstat -wl  $interval $loop_count"
    writeLog "$stat_cmd ..."
    nohup $stat_cmd >> $snapshot_File 2>&1 & 

  else
    writeLog "please install pidstat."
  fi
  
  
  ### (2) gather cpu information 可以从sar中获取
  #snapshot_File=${OUTPUT_DIR}/t_stat_mpstat.snap
  #stat_cmd="mpstat -P ALL $interval $loop_count"
  #writeLog "$stat_cmd ..."
  #$stat_cmd | grep -vP "CPU|^$|Linux|Average" >> $snapshot_File &
  #$stat_cmd >> $snapshot_File &

  ### (3) gather ps information
  nloop=1
  ps_snapShotFile=${OUTPUT_DIR}/t_ps.snap
  netstat_snapShotFile=${OUTPUT_DIR}/t_netstat.snap
  w_snapShotFile=${OUTPUT_DIR}/t_w.snap
  writeLog "ps loop_count=$loop_count"
  while [ $nloop -le $loop_count ]
  do
    snapshot_time="`date "+%H:%M:%S"`"
    echo "snapshot_time ${snapshot_time}"                  >> ${ps_snapShotFile}
    nohup ${pre_nice} ps -ewwo $colList --sort=-%cpu       >> ${ps_snapShotFile} &
	
	echo "snapshot_time ${snapshot_time}"    >> ${netstat_snapShotFile}
	#nohup ${pre_nice}  netstat -antp         >> ${netstat_snapShotFile} &
    nohup ${pre_nice}  netstat -anp         >> ${netstat_snapShotFile} &  #增加对UDP的采集	
	
	echo "snapshot_time ${snapshot_time}"                  >> ${w_snapShotFile}
    nohup w --no-header --ip-addr                          >> ${w_snapShotFile} & 

    sleep $interval
    nloop=`expr $nloop + 1`
  done

  ### (3) The second day, archive output
  (
    tar -czvf  ${archiveDir}/${TODAY}.tgz ${OUTPUT_DIR}
    rm  -rf ${OUTPUT_DIR}
  ) &

  #delete expired archive log
  find ./archive -maxdepth 1 -ctime +${keepPeriod}  -name "*.tgz"  >> $runLogFile
  find ./archive -maxdepth 1 -ctime +${keepPeriod}  -name "*.tgz"  | xargs rm -f

done >/dev/null 2>&1 &
