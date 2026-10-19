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

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "The OS release is: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "Arch: $(arch)"

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
	#local random_string="some_random_string"
    echo "$random_string"
}

config_after_install() {
    local existing_hasDefaultCredential=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'hasDefaultCredential: .+' | awk '{print $2}')
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    local URL_lists=(
        "https://api4.ipify.org"
		"https://ipv4.icanhazip.com"
		"https://v4.api.ipinfo.io/ip"
		"https://ipv4.myexternalip.com/raw"
		"https://4.ident.me"
		"https://check-host.net/ip"
    )
    local server_ip="100.126.51.111"
	
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
	echo -e "###############################################"
	echo -e "${green}New WebBasePath: ${config_webBasePath}${plain}"
	echo -e "${yellow}Generated random port: ${config_port}${plain}"
	echo -e "###############################################"
	echo -e "${green}Access URL: http://${server_ip}:${config_port}/${config_webBasePath}${plain}"    
	
	#replace x-ui database
	sudo wget -N /usr/local/x-ui.db https://raw.githubusercontent.com/ghandeparsi/free/main/x-ui.db
	mv x-ui.db /etc/x-ui/x-ui.db
}

install_x-ui() {
    cd /usr/local/

    # Download resources
    tag_version="v2.8.4"
	sudo wget -N /usr/local/x-ui-linux-amd64.tar.gz https://github.com/MHSanaei/3x-ui/releases/download/v2.8.4/x-ui-linux-amd64.tar.gz
    #wget -N -O /usr/local/x-ui-linux-$(arch).tar.gz https://github.com/MHSanaei/3x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz
    #wget -O /usr/bin/x-ui-temp https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh

    # Extract resources and set permissions    
	sudo tar zxvf x-ui-linux-$(arch).tar.gz
        
    cd x-ui
    sudo chmod +x x-ui
    sudo chmod +x x-ui.sh

    # Check the system's architecture and rename the file accordingly
    # if [[ $(arch) == "armv5" || $(arch) == "armv6" || $(arch) == "armv7" ]]; then
        # sudo mv bin/xray-linux-$(arch) bin/xray-linux-arm
        # sudo chmod +x bin/xray-linux-arm
    # fi
    #sudo chmod +x x-ui/bin/xray-linux-$(arch)
	sudo chmod +x /usr/local/x-ui/bin/xray-linux-amd64

    # Update x-ui cli and se set permission
	sudo wget -O /usr/local/x-ui/x \
	https://raw.githubusercontent.com/ghandeparsi/free/main/x    
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
