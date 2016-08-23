# EmaNkey
Project to connect MTMonkey and Eman-Lite

# Requirements
EmanLite
MTMonkey
Boost library
XMLRPC library

# EmaNkey Process:
For each folder in models/*
 a. If model.out not exists:
  - Check if train.tgt and train.src exist
  - If not exists mono.tgt - copy from defaults/mono.tgt
  - If not exist dev.tgt, dev.src - copy from defaults/dev.*
  - If not exist test.tgt, test.src - copy from defaults/test.*
  - Run train-system.sh from eman-lite
  - Create model.out with model id
 b. If mosesserver.pid not exists
  - Get random free port
  - Launch mosesserver, based on defaults/mosesserver.cmd
  - Write pid and port to mosesserver.pid and mosesserver.port
 c. If worker.pid not exists
  - Create worker.cfg (based on defaults/worker.cfg), modelid from model.out and mosesserver.port, source and target languages from model.ini
  - Create worker.pid
  - Create worker.to.appserver with model and url
  - Start new worker
 d. Update appserver
  - If appserver.port exists, use it
  - Update appserver.cfg based on active workers (one's which have worker.to.appserver)
  - If appserver.pid exists - appserver
  - Start new appserver

# Starting EmaNkey
1. Install all required applications
2. Update settings in process_models.sh (now configuration is set for MetaCentrum environment)
2. Run process_models.sh

# Stopping EmaNkey
1. To stop MTMonkey appserver - run stop_appserver.sh
2. To stop MTMonkey workers - run stop_workers.sh
3. To stop Moses servers - run stop_mosesservers.sh


# Useful info to run mosesserver from eman-lite:
1. cd to folder with moses.final.ini
2. Launch cmd:
LD_LIBRARY_PATH="PATH_TO_BOOST/install/lib/:PATH_TO_XMLRPC/lib:$LD_LIBRARY_PATH" PATH_TO_EMANLITE/install_dir/mosesdecoder/bin/mosesserver --server 1 --server-port MOSES_SERVER_PORT -f PATH_TO_EMANLITE/test/workdir/moses.final.ini


# To run MTMonkey:
1. cd to mtmonkey main folder
2. Server cmd:
python appserver/src/appserver.py -c ../../config-example/appserver.cfg
3. Worker cmd:
python worker/src/worker.py -c config-example/worker.cfg




