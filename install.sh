#install v2.8.4
# 1-upload the file to /usr/local:
# https://github.com/MHSanaei/3x-ui/releases/download/v2.8.4/x-ui-linux-amd64.tar.gz
# 2-upload the file to /usr/bin:
# https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
# 3-make a file with nano install.sh and paste this file, then chmod +x it, then ./install,sh

#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
	#local random_string="some_random_string"
    echo "$random_string"
}

config_after_install() {
    #local server_ip="Your_Server_ip"	
	local server_ip=$(tailscale ip -4)
	local config_webBasePath=$(gen_random_string 18)
	local config_username=$(gen_random_string 10)
	local config_password=$(gen_random_string 10)	
	local config_port=$(shuf -i 1024-62000 -n 1)
	#local config_webBasePath="6GgZNP7Pu4w99H57WX"
	#local config_username="NM4wHdzweB"
	#local config_password="TX14TqGqKs"
	#local config_port="57540"
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
	sudo wget -O /usr/local/x-ui.db \
	https://raw.githubusercontent.com/ghandeparsi/free/main/x-ui.db
	sudo mv /usr/local/x-ui.db /etc/x-ui/x-ui.db
	echo -e "Access URL changed to:"
	echo -e "${green}Access URL: http://${server_ip}:57540/6GgZNP7Pu4w99H57WX${plain}"
}

install_x-ui() {
    cd /usr/local/

    # Download resources
    tag_version="v2.8.4"
	#sudo wget -N /usr/local/x-ui-linux-amd64.tar.gz https://github.com/MHSanaei/3x-ui/releases/download/v2.8.4/x-ui-linux-amd64.tar.gz
	sudo wget -O /usr/local/x-ui-linux-amd64.tar.gz \
	https://github.com/ghandeparsi/free/releases/download/1/x-ui-linux-amd64.tar.gz

    # Extract resources and set permissions    
	#sudo tar zxvf x-ui-linux-amd64.tar.gz
	###########################################################
	echo "STEP 1: Before extraction"
	pwd
	ls -lh /usr/local/x-ui-linux-amd64.tar.gz

	echo "STEP 2: Testing archive"
	sudo tar -tzf /usr/local/x-ui-linux-amd64.tar.gz >/dev/null
	echo "Archive test exit code: $?"

	echo "STEP 3: Extracting archive"
	sudo tar -xzf /usr/local/x-ui-linux-amd64.tar.gz -C /usr/local/
	echo "Extraction exit code: $?"

	echo "STEP 4: Checking extracted files"
	ls -lah /usr/local/x-ui/

	echo "STEP 5: Continuing installation"
	###########################################################
        
    cd x-ui
    sudo chmod +x x-ui
	sudo chmod +x /usr/local/x-ui/bin/xray-linux-amd64

    # Update x-ui cli and se set permission
	#sudo wget -O /usr/local/x-ui/x \
	#https://raw.githubusercontent.com/ghandeparsi/free/main/x    
	sudo mv -f /usr/local/x-ui/x /usr/bin/x-ui
    sudo chmod +x /usr/bin/x-ui
    config_after_install

    sudo cp -f x-ui.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable x-ui
    sudo systemctl start x-ui
    echo -e "${green}x-ui ${tag_version}${plain} installation finished, it is running now..."
    echo -e ""
    echo -e "┌───────────────────────────────────────────────────────┐
│  ${blue}x-ui control menu usages (subcommands):${plain}              │
│                                                       │
│  ${blue}x-ui${plain}              - Admin Management Script          │
│  ${blue}x-ui start${plain}        - Start                            │
│  ${blue}x-ui stop${plain}         - Stop                             │
│  ${blue}x-ui restart${plain}      - Restart                          │
│  ${blue}x-ui status${plain}       - Current Status                   │
│  ${blue}x-ui settings${plain}     - Current Settings                 │
│  ${blue}x-ui enable${plain}       - Enable Autostart on OS Startup   │
│  ${blue}x-ui disable${plain}      - Disable Autostart on OS Startup  │
│  ${blue}x-ui log${plain}          - Check logs                       │
│  ${blue}x-ui banlog${plain}       - Check Fail2ban ban logs          │
│  ${blue}x-ui update${plain}       - Update                           │
│  ${blue}x-ui legacy${plain}       - legacy version                   │
│  ${blue}x-ui install${plain}      - Install                          │
│  ${blue}x-ui uninstall${plain}    - Uninstall                        │
└───────────────────────────────────────────────────────┘"
}

echo -e "${green}Running...${plain}"
install_x-ui $1
