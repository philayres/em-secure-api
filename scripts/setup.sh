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
         { directories: {
           log: './log' # log file location (relative to base directory, or full path)
         }, 
         server: {
           port: 5501,  # port to run the server on
           request_timeout: {  # max time between timestamp and current time (in ms)
              __default: 30000,   # default for all requests
              controller1: {
                __default:10000,   # default for requests to controller1
                action3_get: 60000  # override controller default for action3 get request
              },
              admin: {
                status_get: 5000 # override server default for status get request
              }
           }           
         }  } )"