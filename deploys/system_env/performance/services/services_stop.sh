

# 如果不用移动宽带
sudo systemctl disable --now ModemManager.service

# 如果不想要错误上报
sudo systemctl disable --now apport.service
sudo systemctl disable --now kerneloops.service
sudo systemctl disable --now whoopsie.service