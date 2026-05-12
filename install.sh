#!/bin/bash

INSTALL_DIR="$HOME/.local/share/arch-guardian"
SCRIPT_NAME="arch_guardian.py"
MARKER_START="# ARCH_GUARDIAN_START"
MARKER_END="# ARCH_GUARDIAN_END"

if [[ "$SHELL" == */zsh ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.bashrc"
fi

do_install() {
    clear
    echo -e "\e[1;33mDo you want to install Arch Guardian? (y/n)\e[0m"
    read -p "> " confirm1
    if [[ ! "$confirm1" =~ ^[Yy]$ ]]; then
        echo -e "\e[1;31mInstallation cancelled.\e[0m"
        exit 0
    fi

    echo -e "\e[1;31mAre you sure now? (y/n)\e[0m"
    read -p "> " confirm2
    if [[ ! "$confirm2" =~ ^[Yy]$ ]]; then
        echo -e "\e[1;31mInstallation cancelled.\e[0m"
        exit 0
    fi

    echo -e "\e[1;34m[*] Installing Arch Guardian...\e[0m"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "\e[1;31m[!] Error: Python3 is not installed.\e[0m"
        exit 1
    fi

    mkdir -p "$INSTALL_DIR"

    if [ -f "$SCRIPT_NAME" ]; then
        cp "$SCRIPT_NAME" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    else
        echo -e "\e[1;31m[!] Error: $SCRIPT_NAME not found in current directory.\e[0m"
        exit 1
    fi

    sed -i "/$MARKER_START/,/$MARKER_END/d" "$SHELL_RC"

    cat << EOF >> "$SHELL_RC"
$MARKER_START
alias pacman_check='python3 $INSTALL_DIR/$SCRIPT_NAME'
alias sudo='sudo '
alias pacman='pacman_check'
$MARKER_END
EOF

    clear
    echo -e "\e[1;92m✔ Installation Successful!\e[0m"
    echo -e "\e[1;31m\n###############################"
    echo -e "      PLEASE RESTART TERMINAL"
    echo -e "###############################\e[0m"
    exit 0
}

do_remove() {
    clear
    echo -e "\e[1;33mDo you want to remove Arch Guardian? (y/n)\e[0m"
    read -p "> " confirm1
    if [[ ! "$confirm1" =~ ^[Yy]$ ]]; then
        echo -e "\e[1;34mRemoval cancelled.\e[0m"
        exit 0
    fi

    echo -e "\e[1;31mAre you sure now? (y/n)\e[0m"
    read -p "> " confirm2
    if [[ ! "$confirm2" =~ ^[Yy]$ ]]; then
        echo -e "\e[1;34mRemoval cancelled.\e[0m"
        exit 0
    fi

    echo -e "\e[1;34m[*] Removing Arch Guardian...\e[0m"

    if [ -f "$SHELL_RC" ]; then
        sed -i "/$MARKER_START/,/$MARKER_END/d" "$SHELL_RC"
    fi

    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
    fi

    clear
    echo -e "\e[1;92m✔ Uninstallation Successful!\e[0m"
    echo -e "\e[1;31m\n###############################"
    echo -e "      PLEASE RESTART TERMINAL"
    echo -e "###############################\e[0m"
    exit 0
}

clear
echo -e "\e[1;92m--- Arch Guardian Management ---\e[0m"
echo -e "Target Shell: $SHELL_RC"
echo -e "1) Install"
echo -e "2) Remove"
echo -e "3) Exit"
read -p "Select an option [1-3]: " choice

case $choice in
    1) do_install ;;
    2) do_remove ;;
    3) exit 0 ;;
    *) echo -e "\e[1;31mInvalid option.\e[0m" ;;
esac
