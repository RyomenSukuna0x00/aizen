#!/bin/bash

# Define colors for output
CYAN='\033[1;36m'
RESET='\033[0m'
RED='\033[0;31m'

# List of required tools
tools=("subfinder" "anew" "httpx" "naabu" "subzy" "katana" "gau" "waybackurls" "gf" "qsreplace" "nuclei" "curl" "egrep")

# Function to install a tool
install_tool() {
    local tool=$1
    echo -e "${CYAN}Installing $tool...${RESET}"
    case $tool in
        subfinder|httpx|naabu|nuclei)
            go install -v github.com/projectdiscovery/${tool}/cmd/${tool}@latest ;;
        anew)
            go install -v github.com/tomnomnom/anew@latest ;;
        subzy)
            go install -v github.com/LukaSikic/subzy@latest ;;
        katana)
            go install -v github.com/projectdiscovery/katana/cmd/katana@latest ;;
        gau)
            go install -v github.com/lc/gau@latest ;;
        waybackurls)
            go install -v github.com/tomnomnom/waybackurls@latest ;;
        gf)
            go install -v github.com/tomnomnom/gf@latest ;;
        qsreplace)
            go install -v github.com/tomnomnom/qsreplace@latest ;;
        curl|egrep)
            sudo apt-get install -y $tool ;;
        *)
            echo -e "${RED}Unknown tool: $tool${RESET}"
            return 1 ;;
    esac
}

# Function to move a tool to /usr/local/bin
move_to_local_bin() {
    local tool_path
    tool_path=$(command -v "$1")
    if [[ "$tool_path" != "/usr/local/bin/$1" ]]; then
        echo -e "${CYAN}Moving $1 to /usr/local/bin...${RESET}"
        sudo mv "$tool_path" /usr/local/bin/
    else
        echo -e "${CYAN}$1 is already in /usr/local/bin.${RESET}"
    fi
}

# Check if each tool is installed
for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo -e "${CYAN}$tool is already installed.${RESET}"
        move_to_local_bin "$tool"
    else
        echo -e "${CYAN}$tool not found. Attempting to install...${RESET}"
        if ! install_tool "$tool"; then
            echo -e "${RED}There was a problem installing $tool. Please install it manually.${RESET}"
        else
            move_to_local_bin "$tool"
        fi
    fi
done
sudo chmod +x ~/aizen/autofinder.sh
sudo cp ~/aizen/autofinder.sh /usr/bin/autofinder
sudo chmod +x ~/aizen/aizen.sh
sudo cp ~/aizen/aizen.sh /usr/bin/aizen

echo -e "${CYAN}All required tools are checked.${RESET}"
