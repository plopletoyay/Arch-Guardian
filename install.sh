#!/bin/bash

INSTALL_DIR="/usr/local/share/arch-guardian"
BIN_WRAPPER="/usr/local/bin/pacman"
SCRIPT_NAME="arch_guardian.py"
DEPENDENCIES=("python" "python-pip")

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

    echo -e "\e[1;34m[*] Checking dependencies...\e[0m"
    for pkg in "${DEPENDENCIES[@]}"; do
        if ! /usr/bin/pacman -Qs "$pkg" > /dev/null; then
            echo -e "\e[1;33m[!] $pkg is missing. Installing...\e[0m"
            sudo /usr/bin/pacman -S --noconfirm "$pkg"
        else
            echo -e "\e[1;32m[+] $pkg is already installed.\e[0m"
        fi
    done

    echo -e "\e[1;34m[*] Installing Arch Guardian core...\e[0m"
    sudo mkdir -p "$INSTALL_DIR"
    if [ -f "$SCRIPT_NAME" ]; then
        sudo cp "$SCRIPT_NAME" "$INSTALL_DIR/"
        sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    else
        echo -e "\e[1;31m[!] Error: $SCRIPT_NAME not found in current directory.\e[0m"
        exit 1
    fi

    echo -e "\e[1;34m[*] Creating system wrapper...\e[0m"
    sudo bash -c "cat << 'EOF' > $BIN_WRAPPER
#!/bin/bash
if [[ \"\$*\" == *\"-S\"*\"y\"*\"u\"* ]] || [[ \"\$*\" == *\"-Syu\"* ]]; then
    python3 $INSTALL_DIR/$SCRIPT_NAME \"\$@\"
else
    exec /usr/bin/pacman \"\$@\"
fi
EOF"
    sudo chmod +x "$BIN_WRAPPER"

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
    sudo rm -f "$BIN_WRAPPER"
    sudo rm -rf "$INSTALL_DIR"

    clear
    echo -e "\e[1;92m✔ Uninstallation Successful!\e[0m"
    echo -e "\e[1;31m\n###############################"
    echo -e "      PLEASE RESTART TERMINAL"
    echo -e "###############################\e[0m"
    exit 0
}

clear
echo -e "\e[1;92m--- Arch Guardian Management (System-wide) ---\e[0m"
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
