# Aizen - Lazy Bug Bounty Setup Script

**Aizen** is a setup script tailored for bug bounty hunters who prefer an automated approach to installing essential reconnaissance and scanning tools. This script checks if the required tools are installed, installs any missing ones, and moves them to `/usr/local/bin` for convenient access. Designed for lazy hunters who want to start their hunt with minimal setup.

## Tools Needed

The script will check for and install the following tools if they’re not already present on your system:

1. **subfinder** - Subdomain discovery tool.
2. **anew** - Appends new items to a file without duplicates.
3. **httpx** - Fast and flexible HTTP probing.
4. **naabu** - Port scanner for identifying open ports.
5. **subzy** - Tool for detecting subdomain takeover vulnerabilities.
6. **katana** - Web crawler for discovering assets.
7. **gau** - GetAllUrls for fetching archived URLs.
8. **waybackurls** - Fetches URLs from the Wayback Machine.
9. **gf** - Grep-like tool for finding vulnerabilities.
10. **nuclei** - Vulnerability scanner based on customizable templates.
11. **qsreplace** - Tool for query string manipulation.

## Note
Please install Linkfinder manually

## Installation

Run the following commands in your terminal to make the script executable and start it:

```bash
cd aizen
chmod +x installer.sh
./installer.sh
