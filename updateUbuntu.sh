#!/bin/bash

# defines colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# default config from configuration file
CONFIG_FILE="config.cfg"

# Backup directory for rollback
BACKUP_DIR_BASE="/var/backups/updateUbuntuBackups"

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
    echo " Version: 1.3"
    echo -e "${NC}"
}

# configuration file logic
function load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}=== Loading configuration from $CONFIG_FILE ===${NC}"
        source "$CONFIG_FILE"
    else
        echo -e "${RED}[ERR] Configuration file not found! Using default settings.${NC}"
        auto_reboot=false
        custom_sources=false
    fi
}

# Internet connection check
function check_internet_connection() {
    echo -e "${YELLOW}=== Checking internet connection ===${NC}"
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${GREEN}[+] Internet connection is active.${NC}"
    else
        echo -e "${RED}[ERR] No internet connection detected. Exiting.${NC}"
        exit 1
    fi
}

# System check (e.g., disk space, file system)
function system_check() {
    echo -e "${YELLOW}=== Running system check ===${NC}"
    # Check disk space
    DISK_SPACE=$(df / | tail -1 | awk '{print $4}')
    MIN_SPACE=1048576  # 1 GB in KB
    if [ "$DISK_SPACE" -lt "$MIN_SPACE" ]; then
        echo -e "${RED}[ERR] Not enough disk space! Please free up some space before updating.${NC}"
        exit 1
    else
        echo -e "${GREEN}[+] Sufficient disk space available.${NC}"
    fi

    # Check for file system errors
    echo -e "${YELLOW}[INF] Checking file system integrity...${NC}"
    sudo fsck -Af -M
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERR] File system errors detected! Please resolve these before updating.${NC}"
        exit 1
    else
        echo -e "${GREEN}[+] File system check passed.${NC}"
    fi
}

# Backup creation
function create_backup() {
    BACKUP_DIR="$BACKUP_DIR_BASE/$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}=== Creating system backup in $BACKUP_DIR ===${NC}"
    sudo mkdir -p "$BACKUP_DIR"
    echo -e "${YELLOW}[INF] Backing up /etc directory...${NC}"
    sudo cp -r /etc "$BACKUP_DIR/etc"
    echo -e "${GREEN}[+] Backup created at $BACKUP_DIR.${NC}"
}

# Delete old backups (older than 4 weeks)
function delete_old_backups() {
    echo -e "${YELLOW}=== Deleting old backups (older than 4 weeks) ===${NC}"
    if [ -d "$BACKUP_DIR_BASE" ]; then
        find "$BACKUP_DIR_BASE" -type d -mtime +28 -exec rm -rf {} \;
        echo -e "${GREEN}[+] Old backups have been deleted.${NC}"
    else
        echo -e "${RED}[ERR] Backup directory does not exist. Skipping old backup deletion.${NC}"
    fi
}

# Delete all snapshots manually
function delete_snapshots() {
    echo -e "${YELLOW}=== Deleting all backups in $BACKUP_DIR_BASE ===${NC}"
    if [ -d "$BACKUP_DIR_BASE" ]; then
        sudo rm -rf "$BACKUP_DIR_BASE"/*
        echo -e "${GREEN}[+] All backups have been deleted.${NC}"
    else
        echo -e "${RED}[ERR] Backup directory does not exist. Nothing to delete.${NC}"
    fi
}

# Security updates check
function install_security_updates() {
    echo -e "${YELLOW}=== Installing security updates ===${NC}"
    sudo unattended-upgrades
}


# function to process the custom paketlists
function process_custom_package_list() {
    if [ -f "$1" ]; then
        echo -e "${YELLOW}=== Processing custom package list from $1 ===${NC}"
        while IFS= read -r package; do
            echo -e "${YELLOW}[INF] Checking and updating $package...${NC}"
            sudo apt install --only-upgrade -y "$package"
        done < "$1"
    else
        echo -e "${RED}[ERR] Custom package list file not found: $1. Skipping.${NC}"
    fi
}

# check for updates with apt
function update_apt_packages() {
    echo -e "${GREEN}=== Updating package lists ===${NC}"
    
    if [ "$custom_sources" = true ] && [ -f "$custom_source_list" ]; then
        echo -e "${YELLOW}[INF] Using custom sources from $custom_source_list${NC}"
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
        echo -e "${RED}[ERR] Flatpak is not installed, skipping this step.${NC}"
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
        echo -e "${RED}[ERR] npm is not installed, skipping this step.${NC}"
    fi
}

# check for updates for pip/pip3 packets (global)
function update_pip_packages() {
    if command -v pip &> /dev/null
    then
        echo -e "${YELLOW}=== Checking and updating global pip packages ===${NC}"
        sudo pip install --upgrade $(pip list --outdated | awk '{if(NR>2) print $1}')
    else
        echo -e "${RED}[ERR] pip is not installed, skipping this step.${NC}"
    fi

    if command -v pip3 &> /dev/null
    then
        echo -e "${YELLOW}=== Checking and updating global pip3 packages ===${NC}"
        sudo pip3 install --upgrade $(pip3 list --outdated | awk '{if(NR>2) print $1}')
    else
        echo -e "${RED}[ERR] pip3 is not installed, skipping this step.${NC}"
    fi
}

# check for updates for docker containers
function update_docker_containers() {
    if command -v docker &> /dev/null
    then
        echo -e "${YELLOW}=== Updating Docker containers ===${NC}"
        sudo docker container update $(docker ps -q)
    else
        echo -e "${RED}[ERR] Docker is not installed, skipping this step.${NC}"
    fi
}

# check for docker-compose updates
function update_docker_compose() {
    if command -v docker compose version &> /dev/null
    then
        echo -e "${YELLOW}=== Updating docker-compose ===${NC}"
        sudo apt-get install docker-compose-plugin
    else
        echo -e "${RED}[ERR] docker-compose is not installed, skipping this step.${NC}"
    fi
}

# check for kernel updates
function update_kernel() {
    echo -e "${YELLOW}=== Checking and updating Kernel ===${NC}"
    sudo apt install --install-recommends linux-generic -y
}

# version upgrade (example: 22.04 to 24.04)
function version_upgrade() {
    echo -e "${YELLOW}=== Starting Ubuntu version upgrade ===${NC}"
    sudo do-release-upgrade -f DistUpgradeViewNonInteractive
}

# reboot reminder
function reboot_reminder() {
    if [ -f /var/run/reboot-required ]; then
        echo -e "${RED}[ERR] A reboot is required to complete the updates.${NC}"
        if [ "$auto_reboot" = true ]; then
            echo -e "${YELLOW}[INF] Rebooting system now...${NC}"
            sudo reboot
        fi
    else
        echo -e "${GREEN}[+] No reboot is required.${NC}"
    fi
}

# Main function
function main() {
    local version_upgrade_flag=false
    local delete_snaps_flag=false

    # Argument parsing
    while [[ "$1" != "" ]]; do
        case $1 in
            --upgrade-version)
                version_upgrade_flag=true
                ;;
            --delete-snaps)
                delete_snaps_flag=true
                ;;
            *)
                custom_package_list="$1"
                ;;
        esac
        shift
    done

    # Print banner
    print_banner

    # Load config
    load_config

    # If --upgrade-version is passed, only run the following
    if [ "$version_upgrade_flag" = true ]; then
        check_internet_connection
        update_apt_packages
        version_upgrade
        exit 0
    fi

    # If --delete-snaps is passed, only run delete_snapshots
    if [ "$delete_snaps_flag" = true ]; then
        delete_snapshots
        exit 0
    fi

    # Full process otherwise
    check_internet_connection
    system_check

    # Step 1: Delete old backups
    delete_old_backups

    # Step 2: Create a new backup
    create_backup

    # Step 3: Continue with updates
    update_apt_packages
    update_snap_packages
    update_flatpak_packages
    update_npm_packages
    update_pip_packages
    update_docker_containers
    update_docker_compose
    update_kernel
    install_security_updates

    if [ -n "$custom_package_list" ]; then
        process_custom_package_list "$custom_package_list"
    fi

    reboot_reminder
    echo -e "${GREEN}=== All updates completed! ===${NC}"
}

# starting the script with calling the main function
main "$@"
