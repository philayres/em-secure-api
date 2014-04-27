#!/bin/bash
SVC=re_svc_identities
BASEDIR=/usr/share/$SVC

echo Starting $SVC: `date`
echo Running as: `whoami`

source "/usr/local/rvm/scripts/rvm"
rvm use 2.0

echo Running in $BASEDIR
cd $BASEDIR


ruby $BASEDIR/lib/em_server.rb
