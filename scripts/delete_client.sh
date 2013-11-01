#!/bin/bash
if [ -z "$1" ]; then
  echo usage: script/delete_client.sh client_name confirm
  exit
fi
CONFIRM=\'$2\'
if [ -z "$2" ]; then
  CONFIRM=false
fi
ruby -r "./lib/em_server.rb" -e "if $CONFIRM == 'confirm'; SecureApi::ClientSecret.delete('$1'); puts 'Deleted $1' else ; puts 'Must confirm this action'; end" script 
