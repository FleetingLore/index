#!/bin/bash

# 配置
SERVER="root@160.202.47.107"
BASE_PATH="/var/www"
CONFIG_FILE="projects.conf"
WORKSPACE_ROOT=$(pwd)

if [ -z "$1" ]; then
    echo "用法: ./deploy.sh 项目名"
    echo "或查看配置: ./deploy.sh --list"
    exit 1
fi

if [ "$1" = "--list" ]; then
    echo "配置文件中的项目："
    grep -v '^#' "$CONFIG_FILE" | grep -v '^[[:space:]]*$' | while read -r line; do
        read -r name local_dir remote_path <<< "$line"
        [ -z "$local_dir" ] && local_dir="./$name"
        [ -z "$remote_path" ] && remote_path="$BASE_PATH/$name"
        echo "  $name -> $local_dir -> $remote_path"
    done
    exit 0
fi

PROJECT_NAME=$1

PROJECT_LINE=$(grep -v '^#' "$CONFIG_FILE" | grep -v '^[[:space:]]*$' | grep "^$PROJECT_NAME[[:space:]]")

if [ -z "$PROJECT_LINE" ]; then
    echo "错误: 未找到项目 $PROJECT_NAME"
    exit 1
fi

read -r name local_dir remote_path <<< "$PROJECT_LINE"
[ -z "$local_dir" ] && local_dir="./$name"
[ -z "$remote_path" ] && remote_path="$BASE_PATH/$name"

if [[ "$local_dir" != /* ]]; then
    local_dir="$WORKSPACE_ROOT/$local_dir"
fi

echo "部署项目: $name"

if [ ! -d "$local_dir" ]; then
    echo "错误: 目录不存在 $local_dir"
    exit 1
fi

cd "$local_dir" || exit 1

if [ ! -f "mkdocs.yml" ]; then
    echo "错误: 不是 MkDocs 项目"
    exit 1
fi

mkdocs build || exit 1

# 上传文件
rsync -avz --delete -e ssh site/ $SERVER:$remote_path/ || exit 1

# Nginx 配置 - 使用 heredoc 正确传递变量
ssh $SERVER << ENDSSH
MAIN_CONFIG="/etc/nginx/conf.d/ducia.conf"

if [ ! -f "\$MAIN_CONFIG" ]; then
    cat > \$MAIN_CONFIG << 'NGINXMAIN'
server {
    listen 80;
    server_name ducia.site;
}
NGINXMAIN
fi

if ! grep -q "location /$name" \$MAIN_CONFIG; then
    sed -i "/^}$/i\\
    location /$name {\\
        root /var/www;\\
        try_files \\\$uri \\\$uri/ /$name/index.html;\\
        index index.html;\\
    }" \$MAIN_CONFIG
    
    nginx -t && nginx -s reload
    echo "已添加 $name 到 Nginx 配置"
else
    echo "$name 已存在于 Nginx 配置"
fi
ENDSSH

echo "部署完成: http://ducia.site/$name"
