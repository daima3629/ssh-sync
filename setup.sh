#!/bin/bash
ESC=$(printf '\033')
RESET="${ESC}[0m"

RED="${ESC}[31m"
BLUE="${ESC}[34m"
CYAN="${ESC}[36m"

putsn() {  # solves color emission problem https://qiita.com/ko1nksm/items/d0b066268cda42ff24eb
  printf '%s\n' "$*"
}

# Check required commands exist
if [[ "$(type bw)" = "bw not found" ]]; then
    putsn "${ESC}${RED}Bitwarden CLI isn't installed. Exiting.${RESET}"
    exit 1
fi

if [[ "$(type jq)" = "jq not found" ]]; then
    putsn "${ESC}${RED}jq isn't installed. Exiting.${RESET}"
    exit 1
fi

if [[ "$(type python3)" = "python3 not found" ]]; then
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
read -p "Choose Install Location (${default_install_directory}): " install_directory
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
read -sp "Session key (input is hidden): " session_key
putsn

# Validate session key
if [[ "$(bw status --session $session_key | jq .status | sed 's/\"//g')" != "unlocked" ]]; then
    putsn "${ESC}${RED}Provided session key is not valid. Try again.${RESET}"
    exit 1
fi

