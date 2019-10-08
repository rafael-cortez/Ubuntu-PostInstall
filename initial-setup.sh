#!/bin/bash

## Declaring variables colors ##
RED="\033[1;31m"
GREEN="\033[1;32m"
NC='\033[0m'

## Declaring arrays ##

declare -A EXTERNAL_APPS=([google - chrome]="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb")

REPOS_APPS=("flameshot" "virtualbox" "transmission" "steam" "exfat-fuse" "git")

SNAP_APPS=("spotify" "code --classic" "pycharm-community --classic" "intellij-idea-community --classic"
	"slack --classic" "skype --classic" "wps-office-multilang" "obs-studio" "audacity")

### Verify User ###
if [[ $(id -u) -ne 0 ]]; then
	echo -e "${RED}Only root can run this script"
	exit -1
fi

# Check if command worked
function chk() {
	if [ $? -eq 0 ]; then
		echo -e "\b\b\b\b${GREEN}OK ${NC}"
	else
		echo -e "\b\b\b\b${RED}OK ${NC}"
	fi
}

function update() {
	echo -n "Updating System [    ]"
	apt update &>/dev/null
	chk
	echo -n "Upgrading System [    ]"
	apt dist-upgrade -y &>/dev/null
	chk
	echo -n "Cleaning cache [    ]"
	apt autoclean -y &>/dev/null
	chk
	echo -n "Removing Unused packages [    ]"
	apt autoremove -y &>/dev/null
	chk
	echo -n "Reparing broken packages [    ]"
	dpkg --configure -a
	chk
}

function banner() {
	input_char=$(echo "$@" | wc -c)
	line=$(for i in $(seq 0 $input_char); do printf "-"; done)
	tput bold
	space=${line//-/ }
	echo " ${line}"
	printf '|'
	echo -n "$space"
	printf "%s\n" '|'
	printf '| '
	echo -n "$@"
	printf "%s\n" ' |'
	printf '|'
	echo -n "$space"
	printf "%s\n" '|'
	echo " ${line}"
	tput sgr 0
}

function clean_system() {
	echo -n "Emptying Trash [    ]"
	sudo rm -rf /home/$USER/.local/share/Trash/files/*
	chk
	echo -n "Cleaning /tmp [    ]"
	sudo rm -rf /var/tmp/*
	chk
	echo -n "Removing lock files [    ]"
	rm -rf /var/lib/dpkg/lock-frontend 2>/dev/null
	rm -rf /var/cache/apt/archives/lock 2>/dev/null
	chk
	update
}

banner "Updating system"
clean_system

banner "EXTERNAL DOWNLOADS"
cd /tmp # Making Downloads on tmp directory
for k in "${!EXTERNAL_APPS[@]}"; do
	# Verify if it is already installed
	if [[ $(dpkg -l | grep $k | wc -l) -gt 0 ]]; then
		echo -e "${NC}$k is already ${GREEN} installed ${NC} [ ${GREEN}OK${NC} ]"
		continue
	fi
	echo -ne "${GREEN}Downloading ${NC}$k  [    ]"
	wget ${EXTERNAL_APPS[$k]} -O $k &>/dev/null
	if [ -a $k ]; then
		echo -e "\b\b\b\b${GREEN}OK ${NC}"
		echo -ne "${GREEN}Installing ${NC}$k [    ]"
		dpkg -i $k &>/dev/null
		if [[ $(dpkg -l | grep $k | wc -l) -gt 0 ]]; then
			echo -e "\b\b\b\b${GREEN}OK ${NC}"
		fi
	else
		echo -e "\b\b\b\b\b${RED}FAIL${NC}"
	fi
done

banner "Installing Repository applications"
for ((i = 0; i < ${#REPOS_APPS[@]}; i++)); do
	echo -ne "${GREEN}Installing ${NC}${REPOS_APPS[$i]} [    ]"
	apt-get install -y ${REPOS_APPS[$i]} &>/dev/null
	if [[ $(dpkg -l | grep ${REPOS_APPS[$i]} | wc -l) -gt 0 ]]; then
		echo -e "\b\b\b\b${GREEN}OK ${NC}"
	else
		echo -e "\b\b\b\b\b${RED}FAIL${NC}"
	fi
done

banner "Installing Snap applications"
for ((i = 0; i < ${#SNAP_APPS[@]}; i++)); do
	PKG_FORMATED=$(echo ${SNAP_APPS[$i]} | sed 's/ --classic//')
	echo -ne "${GREEN}Installing ${NC}${PKG_FORMATED} [    ]"
	snap install ${SNAP_APPS[$i]} &>/dev/null
	if [[ $(snap list | grep ${PKG_FORMATED} | wc -l) -gt 0 ]]; then
		echo -e "\b\b\b\b${GREEN}OK ${NC}"
	else
		echo -e "\b\b\b\b\b${RED}FAIL${NC}"
	fi
done

banner "Final Update"
clean_system

banner "Script Done Successfully"
