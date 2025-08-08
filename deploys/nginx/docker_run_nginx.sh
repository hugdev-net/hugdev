
export NGINX_PATH="/opt/apps/nginx"
export HOST_IP="192.168.1.100"

mkdir -p $NGINX_PATH/{conf,html,logs,certs,cache,run}
mkdir -p $NGINX_PATH/conf/conf.d

docker run -d --name nginx \
  -p $HOST_IP:8080:80 \
  -p $HOST_IP:8443:443 \
  -v $NGINX_PATH/html:/usr/share/nginx/html \
  -v $NGINX_PATH/conf/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v $NGINX_PATH/conf/conf.d:/etc/nginx/conf.d:ro \
  -v $NGINX_PATH/logs:/var/log/nginx \
  -v $NGINX_PATH/cache:/var/cache/nginx \
  -v $NGINX_PATH/run:/var/run \
  -v $NGINX_PATH/certs:/etc/nginx/certs:ro \
  --user 1000:1000 \
  --restart unless-stopped \
  nginx:stable
