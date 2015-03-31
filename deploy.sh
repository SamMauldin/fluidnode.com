#!/bin/bash
git pull
npm install
screen -X -S fluidnode quit
screen -dmS fluidnode /home/ubuntu/fluidnode.com/production.sh
