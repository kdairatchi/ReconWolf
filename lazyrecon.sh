 #!/bin/bash

# Enhanced Bug Bounty Automation Script
# Adds: Subdomain enumeration, parameter extraction, vulnerability patterns, parallel processing, reporting
# New Dependencies: subfinder, amass, gf, ffuf, qsreplace, air, subjs, unfurl, Gxss, anew, notify

banner() {
cat <<'EOF'
 __     __                _                    
 \ \   / /__ _ __ _   _  | |    __ _ _____   _ 
  \ \ / / _ \ '__| | | | | |   / _` |_  / | | |
   \ V /  __/ |  | |_| | | |__| (_| |/ /| |_| |
    \_/ \___|_|   \__, | |_____\__,_/___|\__, |
           |___/                  |___/ 
__        __          ____             _    _   _      _     
\ \      / /_ _ _   _| __ )  __ _  ___| | _| | | |_ __| |___ 
 \ \ /\ / / _` | | | |  _ \ / _` |/ __| |/ / | | | '__| / __|
  \ V  V / (_| | |_| | |_) | (_| | (__|   <| |_| | |  | \__ \
   \_/\_/ \__,_|\__, |____/ \__,_|\___|_|\_\\___/|_|  |_|___/
                |___/                                        

                    @VeryLazyTech - Medium (Enhanced Edition)
EOF
}

set -eo pipefail

# Initialize variables
TARGET=""
WORKSPACE="results"
CONFIG_DIR="$HOME/.config/bbtools"
THREADS=20
NOTIFY=false
MODE="full"

usage() {
    echo "Usage: $0 --url <target> [--mode quick|full] [--notify]"
    echo "Options:"
    echo "  --mode     : Scan mode (quick/full) [default: full]"
    echo "  --notify   : Send notifications via notify CLI"
    exit 1
}

check_dependencies() {
    local deps=("waybackurls" "httpx" "nuclei" "subfinder" "amass" "ffuf" "gf" "qsreplace" "subjs" "unfurl")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

setup_environment() {
    mkdir -p "$WORKSPACE" "$CONFIG_DIR"
    [ ! -f "$CONFIG_DIR/patterns.json" ] && wget -q -O "$CONFIG_DIR/patterns.json" https://raw.githubusercontent.com/devanshbatham/ParamSpider/master/gf_profiles/potential.json
}

subdomain_enum() {
    echo "[+] Starting subdomain enumeration..."
    subfinder -d "$TARGET" -silent | anew "$WORKSPACE/subs.txt"
    amass enum -passive -d "$TARGET" -silent | anew "$WORKSPACE/subs.txt"
    cat "$WORKSPACE/subs.txt" | httpx -silent -status-code -location -title -json -o "$WORKSPACE/live_subs.json"
    echo "[+] Found $(wc -l < "$WORKSPACE/subs.txt") subdomains ($(jq length "$WORKSPACE/live_subs.json") live)"
}

url_collection() {
    echo "[+] Collecting URLs..."
    waybackurls "$TARGET" | anew "$WORKSPACE/urls.txt"
    gospider -s "https://$TARGET" -d 2 -t 5 -c 10 --subs --other-source --sitemap --include-js -o "$WORKSPACE/gospider" 
    [ -d "$WORKSPACE/gospider" ] && cat "$WORKSPACE/gospider/*" | grep -Eo 'https?://[^"]+' | anew "$WORKSPACE/urls.txt"
    cat "$WORKSPACE/urls.txt" | grep "\.js" | subjs -c $THREADS | anew "$WORKSPACE/js_urls.txt"
}

param_analysis() {
    echo "[+] Analyzing parameters..."
    cat "$WORKSPACE/urls.txt" | gf potential | anew "$WORKSPACE/params.txt"
    cat "$WORKSPACE/params.txt" | qsreplace -a | tee "$WORKSPACE/all_params.txt"
    cat "$WORKSPACE/params.txt" | Gxss -c $THREADS -p FUZZ | anew "$WORKSPACE/xss_patterns.txt"
}

vulnerability_scan() {
    echo "[+] Starting vulnerability scans..."
    nuclei -l "$WORKSPACE/live_subs.txt" -t "$HOME/nuclei-templates/" -severity low,medium,high,critical -silent -o "$WORKSPACE/nuclei_results.txt"
    
    if [ "$MODE" = "full" ]; then
        echo "[+] Running full scan suite..."
        ffuf -w "$WORKSPACE/urls.txt" -u FUZZ -H "User-Agent: Mozilla/5.0" -t $THREADS -mc all -of csv -o "$WORKSPACE/ffuzz_results.csv"
        air -driver phantomjs -timeout 3 -concurrent $THREADS -i "$WORKSPACE/urls.txt" -o "$WORKSPACE/air_results.txt"
    fi
}

reporting() {
    echo "[+] Generating report..."
    echo "# Bug Bounty Report for $TARGET" > "$WORKSPACE/report.md"
    echo "## Subdomains\n\`\`\`" >> "$WORKSPACE/report.md"
    cat "$WORKSPACE/subs.txt" >> "$WORKSPACE/report.md"
    echo "\`\`\`\n## Vulnerabilities" >> "$WORKSPACE/report.md"
    cat "$WORKSPACE/nuclei_results.txt" >> "$WORKSPACE/report.md"
    echo "\`\`\`\n## JavaScript Findings" >> "$WORKSPACE/report.md"
    [ -f "$WORKSPACE/js_analysis/sensitive_js_data.txt" ] && cat "$WORKSPACE/js_analysis/sensitive_js_data.txt" >> "$WORKSPACE/report.md"
    
    if [ "$NOTIFY" = true ]; then
        echo "[+] Sending notifications..."
        cat "$WORKSPACE/nuclei_results.txt" | notify -silent -bulk
    fi
}

cleanup() {
    echo "[+] Cleaning up temporary files..."
    rm -rf "$WORKSPACE/gospider" 2>/dev/null
}

main() {
    banner
    check_dependencies
    setup_environment
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --url) TARGET="$2"; shift ;;
            --mode) MODE="$2"; shift ;;
            --notify) NOTIFY=true ;;
            *) usage ;;
        esac
        shift
    done

    [ -z "$TARGET" ] && usage
    
    cd "$WORKSPACE" || exit 1
    
    subdomain_enum
    url_collection
    param_analysis
    vulnerability_scan
    reporting
    cleanup
    
    echo "[+] Scan complete! Results saved to $WORKSPACE/"
}

main "$@"
