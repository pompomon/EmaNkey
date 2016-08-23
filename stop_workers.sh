#!/bin/bash
function die {
# avoid colors in logs for now
#  echo -e "\e[31m\e[1m[ERROR]\e[21m Exiting: $@\e[39m" >&2
  echo "[ERROR] Exiting: $@" >&2
  exit 1
}

#scan for models/ folder for new input
MODELS_DIR=models
#current dir
myDir=`pwd`

for workerpid in $MODELS_DIR/*/worker.pid;do
  pid=`cat $workerpid`
  kill $pid || die "Failed to kill $workerpid (pid: $pid)"
  rm $workerpid || die "Failed to kill $workerpid"
done;