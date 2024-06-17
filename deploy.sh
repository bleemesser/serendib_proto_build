#!/bin/bash

# THIS SCRIPT INSTALLS THE APP ON A FRESH UBUNTU SERVER

# Install Git and Nginx
# sudo apt update
# sudo apt upgrade -y
# sudo apt install -y git nginx

# Install npm using NVM
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# nvm install node
# nvm use node

# Install Golang using Snap
# sudo snap install go --classic

# Clone the public git repository
# check if folder exists:
# if [ -d "$HOME/serendib_proto_build" ]; then
#   cd $HOME/serendib_proto_build
#   git pull
# else
#   cd $HOME
#   git clone https://github.com/bleemesser/serendib_proto_build.git
# fi
# cd $HOME/serendib_proto_build

# Copy nginx.conf to /etc/nginx/nginx.conf and reload Nginx
sudo useradd nginx
sudo cp nginx.conf /etc/nginx/nginx.conf
sudo systemctl restart nginx
sudo nginx -s reload

# Create a systemd service file
cat << EOF | sudo tee /etc/systemd/system/pocketbase.service > /dev/null
[Unit]
Description=Pocketbase Service
After=network.target

[Service]
User=$USER
Group=$(id -gn)
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/pocketbase serve --http "127.0.0.1:8090"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable pocketbase.service
sudo systemctl restart pocketbase.service

# Open ports 80 and 443
# sudo iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
# sudo iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
# sudo systemctl restart iptables

# create script that auto-checks the repo for updates
echo "#!/bin/bash
cd $HOME/serendib_proto_build
git fetch origin
if [ \$(git rev-parse HEAD) != \$(git rev-parse origin/main) ]; then
    git pull
    sudo systemctl restart pocketbase.service
fi" > $HOME/update.sh

chmod +x $HOME/update.sh
# create timer file
cat << EOF | sudo tee /etc/systemd/system/pb_update.timer > /dev/null
[Unit]
Description=Pocketbase Update Timer

[Timer]
OnUnitActiveSec=5m
Unit=pb_update.service

[Install]
WantedBy=timers.target
EOF

# create service that runs the update script every 5 minutes
cat << EOF | sudo tee /etc/systemd/system/pb_update.service > /dev/null
[Unit]
Description=Pocketbase Update Service
After=network.target

[Service]
User=$USER
Group=$(id -gn)
WorkingDirectory=$HOME
ExecStart=$HOME/update.sh
Restart=no

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable pb_update.timer
sudo systemctl restart pb_update.timer

sudo systemctl enable pb_update.service
sudo systemctl restart pb_update.service