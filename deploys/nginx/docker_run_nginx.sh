export PROJECT_NAME="app"
export SETUP_PATH="/opt/${PROJECT_NAME}"

export NGINX_PATH="${SETUP_PATH}/nginx"
export HOST_IP="0.0.0.0"
export DOCKER_RUN_USER=$(id -u)
export DOCKER_RUN_GROUP=$(id -g)

#创建目录
mkdir -p $NGINX_PATH/{conf,html,logs,certs,cache,run}
mkdir -p $NGINX_PATH/conf/conf.d

#生成证书
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
-keyout $NGINX_PATH/certs/nginx.key -out $NGINX_PATH/certs/nginx.crt \
-subj "/C=US/ST=California/L=Mountain View/O=xhproxy.org/CN=xhproxy.org"
chmod 644 $NGINX_PATH/certs/*

#复制相关配置文件
# rz nginx.conf

#启动容器
docker run -d --add-host=host.docker.internal:host-gateway \
  --name ${PROJECT_NAME}_nginx \
  -p $HOST_IP:8080:80 \
  -p $HOST_IP:8443:443 \
  -v $NGINX_PATH/html:/usr/share/nginx/html \
  -v $NGINX_PATH/conf/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v $NGINX_PATH/conf/conf.d:/etc/nginx/conf.d:ro \
  -v $NGINX_PATH/logs:/var/log/nginx \
  -v $NGINX_PATH/cache:/var/cache/nginx \
  -v $NGINX_PATH/run:/var/run \
  -v $NGINX_PATH/certs:/etc/nginx/certs:ro \
  --user $DOCKER_RUN_USER:$DOCKER_RUN_GROUP \
  --restart unless-stopped \
  nginx:stable
