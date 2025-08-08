
docker run -d -it --name dev_ubuntu22 --net host -v D:\\works:/opt/works ubuntu:22.04
docker exec -it dev_ubuntu22 bash