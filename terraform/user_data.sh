# Install docker and python in it
#!/bin/bash
curl -fsSL https://test.docker.com -o test-docker.sh
sudo sh test-docker.sh
#install python
sudo apt-get update
sudo apt-get install -y python3 python3-pip