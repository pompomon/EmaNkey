#!/usr/bin/env python

import os
import getopt
import sys
from configobj import ConfigObj


def main():
  inputfile = ''
  outputfile = ''
  moses_port = ''
  moses_model_id = ''
  worker_port = ''
  source_lang = 'en'
  target_lang = 'cs'
  try:
    opts, args = getopt.getopt(sys.argv[1:],"hp:m:w:i:o:s:t:",["moses-port=","moses-model-id=","worker-port=","mtm-input-worker-cfg=","mtm-output-worker-cfg=","source-lang=","target-lang="])
  except getopt.GetoptError:
    print 'generate_worker_cfg.py -p <moses_server_port> -m <moses_model_id> -w <worker_port> i <default_worker_cfg> -o <output_worker_cfg> -s <source_lang> -t <target_lang>'
    sys.exit(2)
  for opt, arg in opts:
    if opt == '-h':
      print 'generate_worker_cfg.py -p <moses_server_port> -m <moses_model_id> -w <worker_port> i <default_worker_cfg> -o <output_worker_cfg> -s <source_lang> -t <target_lang>'
      sys.exit()
    elif opt in ("-i", "--mtm-input-worker-cfg"):
      inputfile = arg
    elif opt in ("-o", "--mtm-output-worker-cfg"):
      outputfile = arg
    elif opt in ("-p", "--moses-port"):
      moses_port = arg
    elif opt in ("-m", "--moses-model-id"):
      moses_model_id = arg
    elif opt in ("-w", "--worker-port"):
      worker_port = arg
    elif opt in ("-s", "--source-lang"):
      source_lang = arg
    elif opt in ("-t", "--target-lang"):
      target_lang = arg

  config = ConfigObj(inputfile)
  config["PORT"]=worker_port.strip()
  config["TRANSLATE_PORT"]=moses_port.strip()
  config["TARGET_LANG"]=(target_lang + "." + moses_model_id).strip()
  config["SOURCE_LANG"]=source_lang.strip()
  config.filename=outputfile
  config.write()

if __name__ == "__main__":
    main()
