
export REDIS_PATH="/opt/apps/redis"
export HOST_IP="192.168.1.100"

mkdir -p $REDIS_PATH/data $REDIS_PATH/conf/
echo '
appendonly yes
protected-mode no
bind 0.0.0.0
requirepass password01' > $REDIS_PATH/conf/redis.conf

docker run -d --name redis -p $HOST_IP:6379:6379 --restart unless-stopped \
  -v $REDIS_PATH/data:/data \
  -v $REDIS_PATH/conf/redis.conf:/etc/redis/redis.conf \
  redis redis-server /etc/redis/redis.conf

docker exec -it redis redis-cli
auth password01
quit

netstat -lnp | grep 6379
