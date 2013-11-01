#!/bin/bash
if [ -z "$1" ]; then
  echo Your mySQL username is required as the first argument in the call
  echo usage: script/setup.sh root 
  exit
fi
bundle install
mkdir ./log
echo Enter your mysql password for user $1
mysql -u $1 -p < ./db/setup_db.sql
ruby -r "./lib/helpers/config_manager.rb" -e "ConfigManager.create_database_config('utf8','mysql2',
         're_svc_records', # db name
         'gen_api', #db username
         'ja89jh',  #db password
        { directories: {log: './log'}, server: {port: 5501}  } )"

