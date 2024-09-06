#!/bin/bash

# defines colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# default config from configuration file
CONFIG_FILE="config.cfg"

# ASCII Banner Funktion
function print_banner() {
    echo -e "${MAGENTA}"
    echo "                     _       _       _   _ _                 _         "
    echo "                    | |     | |     | | | | |               | |        "
    echo "     _   _ _ __   __| | __ _| |_ ___| | | | |__  _   _ _ __ | |_ _   _ "
    echo "    | | | | '_ \\ / _\` |/ _\` | __/ _ \\ | | | '_ \\| | | | '_ \\| __| | | |"
    echo "    | |_| | |_) | (_| | (_| | ||  __/ |_| | |_) | |_| | | | | |_| |_| |"
    echo "     \\__,_| .__/ \\__,_|\\__,_|\\__\\___|\\___/|_.__/ \\__,_|_| |_|\\__|\\__,_|"
    echo "          | |                                                          "
    echo "          |_|                                                          "
    echo " Author: G0urmetD"
    echo " Version: 1.0"
    echo -e "${NC}"
}

# configuration file logic
function load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}=== Loading configuration from $CONFIG_FILE ===${NC}"
        source "$CONFIG_FILE"
    else
        echo -e "${RED}Configuration file not found! Using default settings.${NC}"
        auto_reboot=false
        custom_sources=false
    fi
}

# function to process the custom paketlists
function process_custom_package_list() {
    if [ -f "$1" ]; then
        echo -e "${YELLOW}=== Processing custom package list from $1 ===${NC}"
        while IFS= read -r package; do
            echo -e "${YELLOW}Checking and updating $package...${NC}"
            sudo apt install --only-upgrade -y "$package"
        done < "$1"
    else
        echo -e "${RED}Custom package list file not found: $1. Skipping.${NC}"
    fi
}

# check for updates with apt
function update_apt_packages() {
    echo -e "${GREEN}=== Updating package lists ===${NC}"
    
    if [ "$custom_sources" = true ] && [ -f "$custom_source_list" ]; then
        echo -e "${YELLOW}Using custom sources from $custom_source_list${NC}"
        sudo cp "$custom_source_list" /etc/apt/sources.list
    fi

    sudo apt update

    echo -e "${GREEN}=== Upgrading installed packages ===${NC}"
    sudo apt upgrade -y

    echo -e "${GREEN}=== Upgrading system to the latest version ===${NC}"
    sudo apt full-upgrade -y

    echo -e "${GREEN}=== Removing old and unnecessary packages ===${NC}"
    sudo apt autoremove -y
}

# check for updates with snap packets
function update_snap_packages() {
    echo -e "${YELLOW}=== Checking and updating Snap packages ===${NC}"
    sudo snap refresh
}

# check for updates with flatpak packets
function update_flatpak_packages() {
    if command -v flatpak &> /dev/null
    then
        echo -e "${YELLOW}=== Checking and updating Flatpak packages ===${NC}"
        flatpak update -y
    else
        echo -e "${RED}Flatpak is not installed, skipping this step.${NC}"
    fi
}

# check for updates with npm (global)
function update_npm_packages() {
    if command -v npm &> /dev/null
    then
        echo -e "${YELLOW}=== Checking and updating global npm packages ===${NC}"
        sudo npm update -g
        sudo npm audit fix --force
    else
        echo -e "${RED}npm is not installed, skipping this step.${NC}"
    fi
}

# check for updates for pip/pip3 packets (global)
function update_pip_packages() {
    if command -v pip &> /dev/null
    then
        echo -e "${YELLOW}=== Checking and updating global pip packages ===${NC}"
        sudo pip install --upgrade $(pip list --outdated | awk '{if(NR>2) print $1}')
    else
        echo -e "${RED}pip is not installed, skipping this step.${NC}"
    fi

    if command -v pip3 &> /dev/null
    then
        echo -e "${YELLOW}=== Checking and updating global pip3 packages ===${NC}"
        sudo pip3 install --upgrade $(pip3 list --outdated | awk '{if(NR>2) print $1}')
    else
        echo -e "${RED}pip3 is not installed, skipping this step.${NC}"
    fi
}

# check for updates for docker containers
function update_docker_containers() {
    if command -v docker &> /dev/null
    then
        echo -e "${YELLOW}=== Updating Docker containers ===${NC}"
        sudo docker container update $(docker ps -q)
    else
        echo -e "${RED}Docker is not installed, skipping this step.${NC}"
    fi
}

# check for kernel updates
function update_kernel() {
    echo -e "${YELLOW}=== Checking and updating Kernel ===${NC}"
    sudo apt install --install-recommends linux-generic -y
}

# reboot reminder
function reboot_reminder() {
    if [ -f /var/run/reboot-required ]; then
        echo -e "${RED}A reboot is required to complete the updates.${NC}"
        if [ "$auto_reboot" = true ]; then
            echo -e "${YELLOW}Rebooting system now...${NC}"
            sudo reboot
        fi
    else
        echo -e "${GREEN}No reboot is required.${NC}"
    fi
}

# main function
function main() {
    print_banner
    load_config
    update_apt_packages
    update_snap_packages
    update_flatpak_packages
    update_npm_packages
    update_pip_packages
    update_docker_containers
    update_kernel
    
    # if a custom paketlist is provided
    if [ -n "$1" ]; then
        process_custom_package_list "$1"
    fi
    
    reboot_reminder
    echo -e "${GREEN}=== All updates completed! ===${NC}"
}

# starting the script with calling the main function
main "$@"
