#!/bin/bash
function die {
# avoid colors in logs for now
#  echo -e "\e[31m\e[1m[ERROR]\e[21m Exiting: $@\e[39m" >&2
  echo "[ERROR] Exiting: $@" >&2
  exit 1
}

model=$1
for neededData in train.tgt train.src dev.tgt dev.src test.tgt test.src mono.tgt;do
  if [ ! -f $model/$neededData ];then
    die "$model/$neededData not found, aborting"
  fi;
done;

source emankey.train.conf
#Fix for Eman-lite on MetaCentrum: source /auto/brno2/home/sudarikov/.bashrc
bash $EMAN_LITE_DIR/$EMAN_LITE_TRAIN_SH \
  --mono $model/mono.tgt \
  --dev-src $model/dev.src \
  --dev-tgt $model/dev.tgt \
  --test-src $model/test.src \
  --test-tgt $model/test.tgt \
  $model/workdir \
  $model/train.src \
  $model/train.tgt \
|| die "train-system.sh failed!";
model_id=$(date +"%Y%m%d-%H%M")
echo "$model:$model_id" > $model/model.out
rm $model/model.run