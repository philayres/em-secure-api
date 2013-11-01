#!/bin/bash
if [ -z "$1" ]; then
  echo usage: script/add_client.sh client_name
  exit
fi
REPLACE=$2
if [ -z "$2" ]; then
  REPLACE=false
fi
ruby -r "./lib/em_server.rb" -e "puts 'Shared Secret:' + SecureApi::ClientSecret.create('$1', :replace_client=>$REPLACE)" script 
