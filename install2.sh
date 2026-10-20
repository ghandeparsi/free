#install v2.8.4

#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

config_after_install() {
	local server_ip="Your_Server_ip"
	local config_webBasePath="1234abcd"
	local config_username="username"
	local config_password="password"
	local config_port="12345"
	sudo /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"
	sudo /usr/local/x-ui/x-ui migrate
	
	echo -e "Generated new random login credentials:"
	echo -e "###############################################"
	echo -e "${green}Username: ${config_username}${plain}"
	echo -e "${green}Password: ${config_password}${plain}"
	echo -e "${green}New WebBasePath: ${config_webBasePath}${plain}"
	echo -e "${yellow}Generated random port: ${config_port}${plain}"
	echo -e "${green}Access URL: http://${server_ip}:${config_port}/${config_webBasePath}${plain}"
	echo -e "###############################################"
	
	#replace x-ui database
	sudo wget -O /usr/local/x-ui2.db \
	https://raw.githubusercontent.com/ghandeparsi/free/main/x-ui2.db
	sudo mv /usr/local/x-ui2.db /etc/x-ui/x-ui.db
}

install_x-ui() {
    cd /usr/local/

    # Download resources
	sudo wget -O /usr/local/x-ui-linux-amd64.tar.gz \
	https://github.com/ghandeparsi/free/releases/download/1/x-ui-linux-amd64.tar.gz

    # Extract resources and set permissions    
	sudo tar zxvf x-ui-linux-amd64.tar.gz
        
    cd x-ui
    sudo chmod +x x-ui
	sudo chmod +x /usr/local/x-ui/bin/xray-linux-amd64

    # Update x-ui cli and  set permission
	sudo mv -f /usr/local/x-ui/x /usr/bin/x-ui
    sudo chmod +x /usr/bin/x-ui
    config_after_install

    sudo cp -f x-ui.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable x-ui
    sudo systemctl start x-ui
    echo -e "${green}x-ui ${plain} installation finished, it is running now..."
    echo -e ""
}

echo -e "${green}Running...${plain}"
install_x-ui $1
