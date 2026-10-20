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
echo "CONFIG 1: getting tailscale IP"
server_ip=$(timeout 10 tailscale ip -4 || true)
echo "CONFIG 2: server_ip=$server_ip"

echo "CONFIG 3: x-ui setting"
/usr/local/x-ui/x-ui setting \
  -username "$config_username" \
  -password "$config_password" \
  -port "$config_port" \
  -webBasePath "$config_webBasePath"

echo "CONFIG 4: migrate"
/usr/local/x-ui/x-ui migrate
	
	echo -e "Generated new random login credentials:"
	echo -e "###############################################"
	echo -e "${green}Username: ${config_username}${plain}"
	echo -e "${green}Password: ${config_password}${plain}"
	echo -e "${green}New WebBasePath: ${config_webBasePath}${plain}"
	echo -e "${yellow}Generated random port: ${config_port}${plain}"
	echo -e "${green}Access URL: http://${server_ip}:${config_port}/${config_webBasePath}${plain}"
	echo -e "###############################################"
	
echo "CONFIG 5: download db"
sudo wget -O /usr/local/x-ui.db \
  https://raw.githubusercontent.com/ghandeparsi/free/main/x-ui.db
  

echo "CONFIG 6: move db"
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
echo "STEP 6: chmod x-ui"
sudo chmod +x x-ui
echo "DONE 6"

echo "STEP 7: chmod xray"
sudo chmod +x /usr/local/x-ui/bin/xray-linux-amd64
echo "DONE 7"

echo "STEP 8: install CLI"
sudo mv -f /usr/local/x-ui/x /usr/bin/x-ui
sudo chmod +x /usr/bin/x-ui
echo "DONE 8"

echo "STEP 9: config_after_install"
config_after_install
echo "DONE 9"

echo "STEP 10: systemd"
sudo cp -f x-ui.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable x-ui
sudo systemctl start x-ui
echo "DONE 10"
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
