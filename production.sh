#!/bin/bash
cd /home/ubuntu/fluidnode.com;
while true; do
git pull
npm install
npm start > /home/ubuntu/fluidnode.com/log.txt
done
