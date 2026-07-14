#!/bin/bash

SERVER="root@160.202.47.107"
REMOTE_PATH="/var/www/index"

rsync -avz --delete -e ssh target/ $SERVER:$REMOTE_PATH/

echo "部署完成: http://index.ducia.site"