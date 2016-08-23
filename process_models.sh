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
#directory with default settings/data
DEFAULTS_DIR=defaults
DEFAULTS_DATADIR=$DEFAULTS_DIR/data
DEFAULTS_MTMDIR=$DEFAULTS_DIR/mtmonkey_configs
#Directory with useful scripts 
TOOLS_DIR=tools
#Path to wiseln for linking data
WISELN=$TOOLS_DIR/wiseln
GET_IP=$TOOLS_DIR/get_my_ip.sh
#Train model wrapper
MY_TRAIN_MODEL=train_model.sh
#qsub params
QSUB_RESOURCE="nodes=1:ppn=4:brno,mem=16gb"
#moses server path
MOSESBIN_PATH=~/kconnect/eman-lite/install_dir/mosesdecoder/bin
#Boost path
BOOST_PATH=/auto/brno2/home/sudarikov/boost_release/boost_1_59_0/install/lib/:$BOOST_PATH
#Xmlrpc path
XMLRPS_PATH=/auto/brno2/home/sudarikov/xmlrpc-c-1.33.14/lib:$XMLRPS_PATH
#Moses server attempts count
MOSES_MAX_COUNT=60
#Moses sleep delay
SLEEP_DELAY=2
#MTMonkey workers default language options
DEFAULT_SRC_LANG="en"
DEFAULT_TGT_LANG="cs"
#MTMonkey bin path
MTM_DIR=/auto/brno2/home/sudarikov/mtmonkey
MTM_APPSERVER=$MTM_DIR/appserver/src/appserver.py
MTM_WORKER=$MTM_DIR/worker/src/worker.py
#IP address for MTMonkey appserver
MTM_IP=`bash $GET_IP`
#Current appserver configuration name
mtm_appserver_cfg=current.appserver.cfg
mtm_appserver_port_file=appserver.port
mtm_appserver_pid_file=appserver.pid
mtm_appserver_models_file=current.appserver.models
mtm_appserver_url="/mtmonkey"
appserver_sh=appserver.sh

#Process models
for model in `ls -d $MODELS_DIR/*`;do
  echo "Processing $model";
  #If model was not trained
  if [ ! -f $model/model.out ]; then
    #Check data
    if [ ! -f $model/train.src ] ;then
      echo "$model no source training data" 
      continue
    fi;
    if [ ! -f $model/train.tgt ] ;then
      echo "$model no target training data" 
      continue
    fi;
    for defaultData in dev.tgt dev.src test.tgt test.src mono.tgt;do
      if [ ! -f $model/$defaultData ]; then 
        echo "Linking $defaultData to $model";
        bash $WISELN $DEFAULTS_DATADIR/$defaultData $model/$defaultData;
      fi;
    done;
    #if trainig is already running - skip
    if [ -f $model/model.run ]; then
      continue;
    fi;
    #Remove previous run
    if [ -d $model/workdir ];then
      echo "Removing previous run"
      rm -rf $model/workdir
      rm -f $model/moses.pid $model/moses.log $model/moses.port
      rm -f $model/worker.pid $model/worker.log $model/worker.to.appserver
    fi;
    #Start training
    echo "bash $myDir/$MY_TRAIN_MODEL $myDir/$model" > $model/train.sh
    cd $model
    model_start=$(date +"%Y%m%d-%H%M")
    echo "$model_start" > model.run
    if [ -n "$(type -t qsub)" ] && [ "$(type -t qsub)" = file ]; then
      qsub -q normal -l $QSUB_RESOURCE train.sh
    else
      nohup bash train.sh &
    fi;
    cd $myDir
  fi;
  #If model trained
  if [ -f $model/model.out ]; then
    #Check if mosesserver already started
    if [ ! -f $model/moses.pid ]; then
      #Init new moses server
      echo "Init new moses server"
      new_port=`python $myDir/$TOOLS_DIR/get_port.py`
      cd $model/workdir
      echo "LD_LIBRARY_PATH=\"$BOOST_PATH:$XMLRPS_PATH:$LD_LIBRARY_PATH\" $MOSESBIN_PATH/mosesserver --server 1 --server-port $new_port -f moses.final.ini > ../moses.log &" > mosesstart.sh;
      #Start moses-server
      nohup bash mosesstart.sh > /dev/null 2>&1 &
      cd $myDir/$model
      counter=0
      moses_server_pid_file=/tmp/moses-server.$new_port.pid
      #Wait for moses server to actually start
      while [ ! -f $moses_server_pid_file ]
      do
        sleep $SLEEP_DELAY
        counter=$((counter+1))
        if [ "$counter" -gt "$MOSES_MAX_COUNT" ]; then
          break
        fi;
      done
      #If server started
      if [ -f $moses_server_pid_file ]; then
        #Save pid and port
        cat $moses_server_pid_file > moses.pid
        echo $new_port > moses.port
      else
        echo "Failed to start Moses server for $model. File does not exists: $moses_server_pid_file"
      fi;
      cd $myDir
    fi;
    if [ -f $model/moses.pid ]; then
      #(Re-)start MTMonkey worker
      if [ -f $model/worker.pid ]; then
        worker_pid=`cat $model/worker.pid`
        kill $worker_pid || echo "Failed to kill $model MTMonkey worker (pid: $worker_pid)"
        rm $model/worker.pid 
      fi;
      moses_port=`cat $model/moses.port`
      moses_model_id=`cut -f2 -d':' $model/model.out`
      moses_model_path=`cut -f1 -d':' $model/model.out`
      mtm_worker_port=`python $myDir/$TOOLS_DIR/get_port.py`
      source_lang=$DEFAULT_SRC_LANG
      target_lang=$DEFAULT_TGT_LANG
      if [ -f $model/model.ini ]; then
        source_lang=`cut -f1 -d':' $model/model.ini`
        target_lang=`cut -f2 -d':' $model/model.ini`
      fi
      lang_options=" -s $source_lang -t $target_lang"
      mtm_worker_cfg=$myDir/$model/worker.cfg
      echo "Starting MTM Worker for $model:$moses_model_id"
      python $myDir/$TOOLS_DIR/generate_worker_cfg.py -p $moses_port -m $moses_model_id -w $mtm_worker_port -i $myDir/$DEFAULTS_MTMDIR/worker.cfg -o $mtm_worker_cfg  $lang_options
      echo "python $MTM_WORKER -c $mtm_worker_cfg > $myDir/$model/worker.log &" 'echo $!' "> $myDir/$model/worker.pid" > $model/mtm_worker.sh
      nohup bash $model/mtm_worker.sh > /dev/null 2>&1 &
      echo $source_lang"-"$target_lang.$moses_model_id"@"$MTM_IP":"$mtm_worker_port";" > $model/worker.to.appserver
    fi;
  fi;
done;
#Check and update appserver
cd $myDir
needreload=1 #do we need to reload appserver?
if [ ! -f $mtm_appserver_models_file ]; then
  cat $MODELS_DIR/*/worker.to.appserver | sort | uniq > $mtm_appserver_models_file
else
  needreload=0
  cat $MODELS_DIR/*/worker.to.appserver | sort | uniq > new.appserver.models
  if ! cmp $mtm_appserver_models_file new.appserver.models ; then
    needreload=1
    cat new.appserver.models > $mtm_appserver_models_file
  fi;
  rm new.appserver.models
fi;
#If we need to reload appserver
if [ "$needreload" -gt "0" ]; then
  appserver_port=0
  #kill current appserver
  if [ -f $mtm_appserver_pid_file ]; then
    appserver_pid=`cat $mtm_appserver_pid_file`
    kill $appserver_pid || echo "Failed to kill MTMonkey appserver (pid: $appserver_pid)"
    rm $mtm_appserver_pid_file
  fi;
  #if we have port assigned, use it
  if [ -f $mtm_appserver_port_file ]; then
    appserver_port=`cat $mtm_appserver_port_file`
  else 
    appserver_port=`python $myDir/$TOOLS_DIR/get_port.py`
    echo "$appserver_port" > $mtm_appserver_port_file
  fi;
  workers=`cat current.appserver.models | tr -d "\n"`
  #generate new config
  python $myDir/$TOOLS_DIR/generate_appserver_cfg.py -w $workers -u $mtm_appserver_url -o $mtm_appserver_cfg -p $appserver_port
  #start appserver
  echo "python $MTM_APPSERVER -c $myDir/$mtm_appserver_cfg > $myDir/appserver.log &" 'echo $!' "> $myDir/$mtm_appserver_pid_file" > $appserver_sh
  nohup bash $appserver_sh > /dev/null 2>&1 &
  echo "Appserver started"
fi;
