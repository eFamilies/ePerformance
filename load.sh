#!/bin/sh
#Lever      modified 2014/8/21 10:02:27
db_connect_string="$1"
snap_date="$2"

if [  "$db_connect_string" = "" -o "$snap_date" = "" ]
then
  echo "Usage: read.sh db_connect_string snap_date"
  exit 1
fi

if [ "simnow" = "$db_connect_string" ]
then
  db_connect_string='osm/osm@172.17.161.5/asp'
fi
if [ "test" = "$db_connect_string" ]
then
  db_connect_string='osm/osm@172.19.121.28/sisuo'
fi

logDir=./log
snap_data_Dir=./output/$snap_date
ctl_dir=./db
tables=./db/tables.sql

if [ ! -d $logDir -o ! -d $snap_data_Dir -o ! -d $ctl_dir -o ! -f $tables ]
then
  echo "snap_data_Dir:$snap_data_Dir, ctl_dir:$ctl_dir, tables:$tables"
  exit 1
fi

# create tables
sqlplus $db_connect_string  @$tables

echo load the statistics of cpu ...
stat_name='t_cpu_detail'
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true
stat_name='t_cpu_queue'
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true
stat_name='t_cpu_switch'
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true
stat_name='t_cpu_interrupt'
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true

echo load the statistics of memory ...
stat_name='t_mem_sum'
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true
stat_name='t_mem_swap'
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true

echo  load the statistics of io ...
stat_name='t_disk'
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true

echo  load the statistics of network ...
stat_name='t_iface'
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true
stat_name='t_iface_error'
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true

stat_name='t_ps'
echo  load the $stat_name ...
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true

stat_name='t_netstat'
echo  load the $stat_name ...
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true

stat_name='t_pid_cpu'
echo  load the $stat_name ...
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true

stat_name='t_pid_disk'
echo  load the $stat_name ...
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true

stat_name='t_pid_mem'
echo  load the $stat_name ...
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true

stat_name='t_pid_switch'
echo  load the $stat_name ...
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad direct=true

stat_name='t_w'
echo  load the $stat_name ...
sqlldr $db_connect_string control=$ctl_dir/$stat_name.ctl data=$snap_data_Dir/$stat_name.txt log=${logDir}/${stat_name}.log bad=${logDir}/${stat_name}.bad  errors=999999999
