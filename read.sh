#!/bin/sh
#Lever      modified 2013/8/21 10:02:27

snap_date=$1
start_time=$2
end_time=$3

if [  "$snap_date" = "" -o "$start_time" = "" -o "$end_time" = "" ]
then
  echo "Usage: read.sh SNAP_DATE START_TIME END_TIME"
  exit 1
fi

#start_time="08:00:00"
#end_time="08:30:00"
range="-s $start_time -e $end_time"
# -s [ hh:mm:ss ]
# -e [ hh:mm:ss ]  -s 14:20 -e 15:00
# sample:sar -f /var/adm/sa/sa22 -s 14:20 -e 15:00 -w -q -i 4

snap_Data_DIR=./output/$snap_date
sar_snap_data=$snap_Data_DIR/t_stat_sar.snap

export LANG=c

###(1) cpu
echo "Report activity for CPU  ..."
# -P { cpu | ALL }
# Reportper ¨Cprocessor statistics for the specified processor or processors. Specifying the ALL keyword reports statistics for each individual processor
# , and globally for all processors. 
stat_name='t_cpu_detail'
snap_Data=${snap_Data_DIR}/$stat_name.txt
sar -P ALL -f $sar_snap_data $range |  grep -vP "^Linux|%idle$|^ *$|^Average" > $snap_Data

# -q Report queue length and load averages. The following values are displayed:
stat_name='t_cpu_queue'
snap_Data=${snap_Data_DIR}/$stat_name.txt
sar -q -f $sar_snap_data $range |   grep -vP "^Linux|RESTART$|ldavg-15$|^ *$|^Average" > $snap_Data

# -w Report system switching activity.
stat_name='t_cpu_switch'
snap_Data=${snap_Data_DIR}/$stat_name.txt
sar -w -f $sar_snap_data $range |  grep -vP "^Linux|RESTART$|cswch/s$|^ *$|^Average" > $snap_Data

#  Report statistics for a given interrupt.The SUM keyword  indicates  that the total number of interrupts received per second is to be displayed. 
stat_name='t_cpu_interrupt'
snap_Data=${snap_Data_DIR}/$stat_name.txt
sar -I SUM -f $sar_snap_data $range |  grep -vP "^Linux|RESTART$|intr/s$|^ *$|^Average" > $snap_Data

### £¨2£©Memory
echo "Report memory statistics. The following values are displayed ..."
stat_name='t_mem_sum'
snap_Data=${snap_Data_DIR}/$stat_name.txt
sar -R -f $sar_snap_data $range |  grep -vP "^Linux|RESTART$|campg/s$|^ *$|^Average" > $snap_Data

# Report memory and swap space utilization statistics.  The following values are displayed:
echo "Report memory and swap space utilization statistics ..."
stat_name='t_mem_swap'
snap_Data=${snap_Data_DIR}/$stat_name.txt
sar -r -f $sar_snap_data $range |  grep -vP "^Linux|kbswpcad$|^ *$|^Average" > $snap_Data

###£¨3£©IO
echo "Report activity for each block device  ..."
stat_name='t_disk'
snap_Data=${snap_Data_DIR}/$stat_name.txt
sar -dp -f $sar_snap_data $range | grep -vP "%util$|^ *$|^Linux|^Average" > $snap_Data


###£¨4£©Network
echo "Report network statistics  ..."
stat_name='t_iface'
snap_Data=${snap_Data_DIR}/$stat_name.txt
sar -n DEV -f $sar_snap_data $range | grep -vP "rxmcst/s$|^ *$|^Linux|^Average" > $snap_Data

stat_name='t_iface_error'
snap_Data=${snap_Data_DIR}/$stat_name.txt
sar -n EDEV -f $sar_snap_data $range | grep -vP "^Linux|RESTART$|txfifo/s$|^ *$|^Average" > $snap_Data

### (5) process
echo "Report every alive process"
stat_name='t_ps'
ps_snap_data=${snap_Data_DIR}/$stat_name.snap
sqlldr_data=${snap_Data_DIR}/$stat_name.txt
awk -v start_time=$start_time -v end_time=$end_time '
BEGIN{
  b_print=0
  awkv_snap_time=0
}
{
  if ( "STARTED" != $1 )
  {
    awkv_snap_date=$1
    if ( "snapshot_time" == $1 )
    {
      awkv_snap_time=substr($2,1,8)
	  awkv_snap_hms=$2

      if ( awkv_snap_time >= start_time )
        b_print=1

      if ( awkv_snap_time >= end_time )
        exit
    }
    else
    {
      if ( b_print == 1 )
        printf "%s %s\n", awkv_snap_hms, $0
    }
  }
}' $ps_snap_data > $sqlldr_data


### (6) netstat
echo "read netstat information"
stat_name='t_netstat'
netstat_snap_data=${snap_Data_DIR}/$stat_name.snap
sqlldr_data=${snap_Data_DIR}/$stat_name.txt
awk -v start_time=$start_time -v end_time=$end_time '
BEGIN{
  b_print=0
  awkv_snap_time=0
}
{
  if ( "tcp" == $1  || "udp" == $1 || "snapshot_time" == $1 )
  {
    if ( "snapshot_time" == $1 )
    {
      awkv_snap_time=substr($2,1,8)
	  awkv_snap_hms=$2

      if ( awkv_snap_time >= start_time )
        b_print=1

      if ( awkv_snap_time >= end_time )
        exit
    }
    else
    {
      if ( b_print == 1 )   
        if ( "udp" == $1 )      
          printf "%s %s %s %s %s %s %s %s \n", awkv_snap_hms, $1, $2, $3, $4, $5, "udp", $6 
        else
          printf "%s %s\n", awkv_snap_hms, $0
    }
  }
}' $netstat_snap_data > $sqlldr_data


### (7) PIDSTAT
pidstat > /dev/null 
if [ $? -ne 0 ]
then
  exit 0
fi

stat_name='t_pid_cpu'
echo "read $stat_name information"
snap_data=${snap_Data_DIR}/$stat_name.snap
sqlldr_data=${snap_Data_DIR}/$stat_name.txt
awk -v start_time=$start_time -v end_time=$end_time '
BEGIN{
  b_print=0
  awkv_snap_time=0
}
{
  if ( "Linux" != $1 && "PID" != $2  )
  {
    awkv_snap_time=substr($1,1,8)
	
	if ( awkv_snap_time >= start_time )
	  b_print=1

	if ( awkv_snap_time >= end_time )
      exit 
		
	if ( b_print == 1 )   
       printf "%s\n", $0		  
  }
}' $snap_data > $sqlldr_data


stat_name='t_pid_disk'
echo "read $stat_name information"
snap_data=${snap_Data_DIR}/$stat_name.snap
sqlldr_data=${snap_Data_DIR}/$stat_name.txt
awk -v start_time=$start_time -v end_time=$end_time '
BEGIN{
  b_print=0
  awkv_snap_time=0
}
{
  if ( "Linux" != $1 && "PID" != $2  )
  {
    awkv_snap_time=substr($1,1,8)
	
	if ( awkv_snap_time >= start_time )
	  b_print=1

	if ( awkv_snap_time >= end_time )
      exit 
		
	if ( b_print == 1 )   
       printf "%s\n", $0		  
  }
}' $snap_data > $sqlldr_data


stat_name='t_pid_mem'
echo "read $stat_name information"
snap_data=${snap_Data_DIR}/$stat_name.snap
sqlldr_data=${snap_Data_DIR}/$stat_name.txt
awk -v start_time=$start_time -v end_time=$end_time '
BEGIN{
  b_print=0
  awkv_snap_time=0
}
{
  if ( "Linux" != $1 && "PID" != $2  )
  {
    awkv_snap_time=substr($1,1,8)
	
	if ( awkv_snap_time >= start_time )
	  b_print=1

	if ( awkv_snap_time >= end_time )
      exit 
		
	if ( b_print == 1 )   
       printf "%s\n", $0		  
  }
}' $snap_data > $sqlldr_data


stat_name='t_pid_switch'
echo "read $stat_name information"
snap_data=${snap_Data_DIR}/$stat_name.snap
sqlldr_data=${snap_Data_DIR}/$stat_name.txt
awk -v start_time=$start_time -v end_time=$end_time '
BEGIN{
  b_print=0
  awkv_snap_time=0
}
{
  if ( "Linux" != $1 && "PID" != $2  )
  {
    awkv_snap_time=substr($1,1,8)
	
	if ( awkv_snap_time >= start_time )
	  b_print=1

	if ( awkv_snap_time >= end_time )
      exit 
		
	if ( b_print == 1 )   
       printf "%s\n", $0		  
  }
}' $snap_data > $sqlldr_data



### (5) t_w
echo "Report every user logined"
stat_name='t_w'
ps_snap_data=${snap_Data_DIR}/$stat_name.snap
sqlldr_data=${snap_Data_DIR}/$stat_name.txt
awk -v start_time=$start_time -v end_time=$end_time '
BEGIN{
  b_print=0
  awkv_snap_time=0
}
{
	awkv_snap_date=$1
	if ( "snapshot_time" == $1 )
	{
	  awkv_snap_time=substr($2,1,8)
	  awkv_snap_hms=$2

	  if ( awkv_snap_time >= start_time )
		b_print=1

	  if ( awkv_snap_time >= end_time )
		exit
	}
	else
	{
	  if ( b_print == 1 )
		printf "%s %s\n", awkv_snap_hms, $0
	}
}' $ps_snap_data > $sqlldr_data



