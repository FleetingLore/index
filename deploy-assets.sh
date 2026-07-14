#!/bin/bash

SERVER="root@160.202.47.107"
REMOTE_PATH="/var/www/assets"

rsync -avz --delete -e ssh fleetinglore.github.io/lore-pages-src/ $SERVER:$REMOTE_PATH/lore-pages-src/

echo "部署完成: https://assets.ducia.site/lore-pages-src/"
