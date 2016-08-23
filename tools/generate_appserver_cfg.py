#!/usr/bin/env python

import os
import getopt
import sys

def main():
  url = '/mtmonkey'
  outputfile = ''
  app_port = ''
  workers = ''
  try:
    opts, args = getopt.getopt(sys.argv[1:],"hu:o:w:p:",["mtm-appserver-url=","mtm-output-appserver-cfg=","workers=","port="])
  except getopt.GetoptError:
    print 'generate_appserver_cfg.py -u <appserver_url> -o <output_cfg> -w <workers_links>'
    sys.exit(2)
  for opt, arg in opts:
    if opt == '-h':
      print 'generate_appserver_cfg.py -u <appserver_url> -o <output_cfg> -w <workers_links>'
      sys.exit()
    elif opt in ("-u", "--mtm-appserver-url"):
      url = arg
    elif opt in ("-o", "--mtm-output-appserver-cfg"):
      outputfile = arg
    elif opt in ("-p", "--port"):
      app_port = arg
    elif opt in ("-w", "--workers"):
      workers = arg
  
  config = {}
  PORT=app_port.strip()
  URL=url.strip()
  with open(outputfile, 'w') as outfile:
    outfile.write("PORT = " + PORT.strip() + "\n")
    outfile.write("URL = '" + URL.strip() + "'\n")
    outfile.write("WORKERS = {" + "\n")
    for worker in workers.split(";"):
      if "@" in worker:
        (model, ip) = worker.split("@")
        outfile.write("\t'" + model + "':['" + ip + "'],\n")
    outfile.write("}")
  
if __name__ == "__main__":
    main()
