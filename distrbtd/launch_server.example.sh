#!/bin/sh
# This is sample "user data" that could be used while launching a server instance 
# This could/should be added to .shrc during init
export AMAZON_ACCESS_KEY_ID='URACCESSKEYH3RE'
export AMAZON_SECRET_ACCESS_KEY='UR+S3CR3T+ACCESS+KEY+HERE'
export GEOCODER_BUCKET='pick-a-bucket'
export GEOCODER_FLOCK='flock-name'
export CLIENT_CHUNK_SIZE=250
export GEOCODER_DB='/opt/tiger/geocoder.db'

cd /home/ubuntu/src/geocoder/distrbtd/
ruby -rubygems geo-server.rb
