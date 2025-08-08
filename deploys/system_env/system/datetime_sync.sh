
# Date and Time Synchronization
sudo apt update
sudo apt install -y chrony
sudo systemctl enable chronyd
sudo systemctl restart chronyd
chronyc sources
