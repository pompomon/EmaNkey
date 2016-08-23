#!/bin/bash
function die {
# avoid colors in logs for now
#  echo -e "\e[31m\e[1m[ERROR]\e[21m Exiting: $@\e[39m" >&2
  echo "[ERROR] Exiting: $@" >&2
  exit 1
}

#current dir
myDir=`pwd`
mtm_appserver_pid_file=appserver.pid
pid=`cat $mtm_appserver_pid_file`
kill $pid || die "Failed to kill MTMonkey appserver (pid: $pid)"
rm $mosespid || die "Failed to remove $mtm_appserver_pid_file"
