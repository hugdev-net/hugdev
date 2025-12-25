
export REDIS_PATH="/opt/apps/redis"
export HOST_IP="127.0.0.1"
export REDIS_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
echo "REDIS_PASSWORD: $REDIS_PASSWORD"
export DOCKER_RUN_USER=$(id -u)
export DOCKER_RUN_GROUP=$(id -g)

mkdir -p $REDIS_PATH/data $REDIS_PATH/conf/
echo "
appendonly yes
protected-mode no
bind 0.0.0.0
requirepass $REDIS_PASSWORD" > $REDIS_PATH/conf/redis.conf

docker run -d --name redis -p $HOST_IP:6379:6379 \
  -v $REDIS_PATH/data:/data \
  -v $REDIS_PATH/conf/redis.conf:/etc/redis/redis.conf \
  --user $DOCKER_RUN_USER:$DOCKER_RUN_GROUP \
  --restart unless-stopped \
  redis redis-server /etc/redis/redis.conf

docker exec -it redis redis-cli
auth $REDIS_PASSWORD
quit

netstat -lnp | grep 6379
