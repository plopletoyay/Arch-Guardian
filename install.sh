#!/bin/bash
set -euo pipefail

INSTALL_DIR="/usr/local/share/arch-guardian"
BIN_WRAPPER="/usr/local/bin/pacman"
SCRIPT_NAME="arch_guardian.py"
DEPENDENCIES=("python" "python-feedparser" "python-requests")

RED="\e[1;31m"
GREEN="\e[1;92m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
RESET="\e[0m"

is_installed() {
    [[ -f "$BIN_WRAPPER" && -f "$INSTALL_DIR/$SCRIPT_NAME" ]]
}

confirm_twice() {
    local q1="$1" q2="$2"
    echo -e "${YELLOW}${q1}${RESET}"
    read -p "> " c1
    [[ "$c1" =~ ^[Yy]$ ]] || return 1
    echo -e "${RED}${q2}${RESET}"
    read -p "> " c2
    [[ "$c2" =~ ^[Yy]$ ]] || return 1
    return 0
}

do_install() {
    clear

    if is_installed; then
        echo -e "${YELLOW}[!] Arch Guardian is already installed.${RESET}"
        echo -e "    Reinstalling will overwrite the current version."
        echo
    fi

    if ! confirm_twice \
        "Do you want to install Arch Guardian? (y/n)" \
        "Are you sure? This will create a pacman wrapper. (y/n)"; then
        echo -e "${RED}Installation cancelled.${RESET}"
        exit 0
    fi

    if [[ ! -f "$SCRIPT_NAME" ]]; then
        echo -e "${RED}[!] Error: $SCRIPT_NAME not found in current directory.${RESET}"
        exit 1
    fi

    echo -e "\n${BLUE}[*] Checking dependencies...${RESET}"
    for pkg in "${DEPENDENCIES[@]}"; do
        if /usr/bin/pacman -Qs "^${pkg}$" > /dev/null 2>&1; then
            echo -e "${GREEN}[+] $pkg is already installed.${RESET}"
        else
            echo -e "${YELLOW}[!] $pkg is missing. Installing...${RESET}"
            if ! sudo /usr/bin/pacman -S --noconfirm "$pkg"; then
                echo -e "${RED}[!] Failed to install $pkg. Aborting.${RESET}"
                exit 1
            fi
        fi
    done

    echo -e "\n${BLUE}[*] Installing Arch Guardian core...${RESET}"
    if ! sudo mkdir -p "$INSTALL_DIR"; then
        echo -e "${RED}[!] Failed to create $INSTALL_DIR. Aborting.${RESET}"
        exit 1
    fi
    sudo cp "$SCRIPT_NAME" "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

    echo -e "${BLUE}[*] Creating system wrapper...${RESET}"
    sudo tee "$BIN_WRAPPER" > /dev/null << EOF
#!/bin/bash
_has_flag() {
    local flag="\$1"; shift
    for arg in "\$@"; do [[ "\$arg" == "\$flag" ]] && return 0; done
    return 1
}
_combined_has() {
    local combined="\$1"; shift
    for arg in "\$@"; do [[ "\$arg" == -* && "\$arg" == *S* && "\$arg" == *y* && "\$arg" == *u* ]] && return 0; done
    return 1
}
if _combined_has "" "\$@" || { _has_flag "-S" "\$@" && _has_flag "-y" "\$@" && _has_flag "-u" "\$@"; } || _has_flag "-Syu" "\$@" || _has_flag "-Syyu" "\$@"; then
    exec python3 "$INSTALL_DIR/$SCRIPT_NAME"
else
    exec /usr/bin/pacman "\$@"
fi
EOF
    sudo chmod +x "$BIN_WRAPPER"

    clear
    echo -e "${GREEN}✔ Installation Successful!${RESET}"
    echo -e "${RED}\n###############################"
    echo -e "      PLEASE RESTART TERMINAL"
    echo -e "###############################${RESET}"
    exit 0
}

do_remove() {
    clear

    if ! is_installed; then
        echo -e "${YELLOW}[!] Arch Guardian does not appear to be installed.${RESET}"
        exit 1
    fi

    if ! confirm_twice \
        "Do you want to remove Arch Guardian? (y/n)" \
        "Are you sure? This will restore the original pacman command. (y/n)"; then
        echo -e "${BLUE}Removal cancelled.${RESET}"
        exit 0
    fi

    echo -e "\n${BLUE}[*] Removing system files...${RESET}"
    sudo rm -f "$BIN_WRAPPER"
    sudo rm -rf "$INSTALL_DIR"

    echo -e "${BLUE}[*] Removing user cache and logs...${RESET}"
    local xdg_cache="${XDG_CACHE_HOME:-$HOME/.cache}"
    local xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
    rm -rf "${xdg_cache}/arch-guardian"
    rm -rf "${xdg_data}/arch-guardian"

    clear
    echo -e "${GREEN}✔ Uninstallation Successful!${RESET}"
    echo -e "${RED}\n###############################"
    echo -e "      PLEASE RESTART TERMINAL"
    echo -e "###############################${RESET}"
    exit 0
}

do_status() {
    clear
    echo -e "${BLUE}--- Arch Guardian Status ---${RESET}\n"
    if is_installed; then
        echo -e "${GREEN}[✔] Installed${RESET}"
        echo -e "    Core : $INSTALL_DIR/$SCRIPT_NAME"
        echo -e "    Wrapper : $BIN_WRAPPER"
        local xdg_cache="${XDG_CACHE_HOME:-$HOME/.cache}"
        local xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
        local cache_file="${xdg_cache}/arch-guardian/feed_cache.json"
        local log_file="${xdg_data}/arch-guardian/arch-guardian.log"
        [[ -f "$cache_file" ]] && echo -e "    Cache : $cache_file ($(du -sh "$cache_file" 2>/dev/null | cut -f1))" || echo -e "    Cache : not yet created"
        [[ -f "$log_file"   ]] && echo -e "    Log   : $log_file ($(wc -l < "$log_file") lines)" || echo -e "    Log   : not yet created"
    else
        echo -e "${RED}[✘] Not installed${RESET}"
    fi
    echo
    read -n1 -rp "Press any key to return to menu..." _
    exec "$0"
}

clear
echo -e "${GREEN}--- Arch Guardian Management (System-wide) ---${RESET}"
if is_installed; then
    echo -e "    Status: ${GREEN}Installed${RESET}"
else
    echo -e "    Status: ${RED}Not installed${RESET}"
fi
echo
echo -e "1) Install"
echo -e "2) Remove"
echo -e "3) Status"
echo -e "4) Exit"
read -p "Select an option [1-4]: " choice
case $choice in
    1) do_install ;;
    2) do_remove ;;
    3) do_status ;;
    4) exit 0 ;;
    *) echo -e "${RED}Invalid option.${RESET}" ;;
esac
