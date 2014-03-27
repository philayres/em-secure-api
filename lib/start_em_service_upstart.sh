#!/bin/bash
SVC=em-secure-api
BASEHOME=/home/vagrant

BASEDIR=$BASEHOME/install-dir/$SVC

echo Starting $SVC: `date`
echo Running as: `whoami`


# Load RVM into a shell session *as a function*
if [[ -s "$BASEHOME/.rvm/scripts/rvm" ]] ; then
  # First try to load from a user install
  source "$BASEHOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
else
  printf "ERROR: An RVM installation was not found.\n"
fi

rvm use 2.0

echo Running in $BASEDIR

cd $BASEDIR
ruby $BASEDIR/lib/em_server.rb
