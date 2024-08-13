#!/bin/bash
ESC=$(printf '\033')
RESET="${ESC}[0m"

RED="${ESC}[31m"
BLUE="${ESC}[34m"
CYAN="${ESC}[36m"

putsn() {  # solves color emission problem https://qiita.com/ko1nksm/items/d0b066268cda42ff24eb
  printf '%s\n' "$*"
}

uuidv7() {  # Reference: https://github.com/nalgeon/uuidv7/blob/main/src/uuidv7.sh
    timestamp=$(date +%s)000
    timestamp_hi=$(( timestamp >> 16 ))
    timestamp_lo=$(( timestamp & 0xFFFF ))

    rand_a=0x$(LC_ALL=C tr -dc '0-9a-f' < /dev/urandom|head -c4)
    ver_rand_a=$(( 0x7000 | ( 0xFFF & rand_a ) ))
    rand_b_hi=0x$(LC_ALL=C tr -dc '0-9a-f' < /dev/urandom|head -c4)
    var_rand_hi=$(( 0x8000 | ( 0x3FFF & rand_b_hi ) ))
    rand_b_lo=$(LC_ALL=C tr -dc '0-9a-f' < /dev/urandom|head -c12)

    printf "%08x-%04x-%04x-%4x-%s" "$timestamp_hi" "$timestamp_lo" "$ver_rand_a" "$var_rand_hi" "$rand_b_lo"
}

# Check required commands exist
if [[ -z "$(command -v bw)" ]]; then
    putsn "${ESC}${RED}Bitwarden CLI isn't installed. Exiting.${RESET}"
    exit 1
fi

if [[ -z "$(command -v jq)" ]]; then
    putsn "${ESC}${RED}jq isn't installed. Exiting.${RESET}"
    exit 1
fi

if [[ -z "$(command -v wget)" ]]; then
    putsn "${ESC}${RED}wget isn't installed. Exiting.${RESET}"
    exit 1
fi

if [[ -z "$(command -v python3)" ]]; then
    putsn "${ESC}${RED}Python3 isn't installed. Exiting.${RESET}"
    exit 1
fi

# Check Python version
python_version=$(python3 -V | cut -d " " -f2)
minor=$(echo $python_version | cut -d "." -f2)

if [[ $minor -lt 10 ]]; then
    putsn "${ESC}${RED}Python3 is too old. It must be greater than 3.9.${RESET}"
    exit 1
fi

# Ask install directory
default_install_directory=${HOME}/.local/ssh-sync/
read -p "Enter install location (${default_install_directory}): " install_directory
if [[ -z install_directory ]]; then
    install_directory=default_install_directory
fi

# Ask bitwarden CLI session token
putsn
putsn "ssh-sync needs Bitwarden CLI session key."
putsn "Follow the steps below in another terminal and obtain the session key."
putsn "1. Execute ${ESC}${CYAN}bw login${RESET} and follow the login step (if you're not already logged in)."
putsn "2. Execute ${ESC}${CYAN}bw unlock${RESET} and input your master password."
putsn "3. Copy displayed session key and paste here."
putsn
read -sp "Session key (input is hidden): " session_key
putsn

# Validate session key
if [[ "$(bw status --session $session_key | jq .status | sed 's/\"//g')" != "unlocked" ]]; then
    putsn "${ESC}${RED}Provided session key is not valid. Try again.${RESET}"
    exit 1
fi

# Ask the folder where secret keys are stored
putsn
read -p "Enter the folder name where secret keys are stored (secret_keys): " folder_name
if [[ -z folder_name ]]; then
    folder_name="secret_keys"
fi

# Create local setting json
mkdir -p $HOME/.config/ssh-sync
device_id="$(uuidv7)"
jq -ncM ".deviceId=\"${device_id}\"" | \
jq -cM ".installDirectory=\"${install_directory}\"" | \
jq -cM ".sessionKey=\"${session_key}\""
jq -cM ".bwSecretFolder=\"${folder_name}\"" | \
jq -cM ".conflicting_keys={}" | \
jq -cM ".conflicting_configs={}" > ${HOME}/.config/ssh-sync/config.json

# Add/Create bitwarden setting json


# Install Python script
putsn "${ESC}${BLUE}Downloading and installing Python script...${RESET}"
mkdir -p "${install_directory}"
wget -q -O - "urlurl" > ${install_directory}/daemon.py

# Install service
putsn "${ESC}${BLUE}Downloading and installing service file...${RESET}"
mkdir -p $HOME/.config/systemd/user/
wget -q -O - "urlu" > $HOME/.config/systemd/user/ssh-sync.service
systemctl --user enable ssh-sync.service

# Create venv
python3 -m venv ${install_directory}/.venv

# Install required Python libraries
putsn "${ESC}${BLUE}Installing required python libraries to the venv..."
source ${install_directory}/.venv/bin/activate
pip install -q "urlurl"
deactivate

# Start daemon
systemctl --user start ssh-sync.service

putsn "Installation completed. "
