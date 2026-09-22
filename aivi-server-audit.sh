
#!/usr/bin/env bash
#
# AIVI Server Audit v1.0
# Authorized server/web security assessment orchestrator
#
# IMPORTANT:
# Run only against systems you own or have explicit authorization to test.
#

set -uo pipefail

VERSION="1.0.0"

# ============================================================
# COLORS
# ============================================================

if [[ -t 1 ]]; then
    RED="\033[1;31m"
    GREEN="\033[1;32m"
    YELLOW="\033[1;33m"
    BLUE="\033[1;34m"
    CYAN="\033[1;36m"
    WHITE="\033[1;37m"
    DIM="\033[2m"
    RESET="\033[0m"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    WHITE=""
    DIM=""
    RESET=""
fi

# ============================================================
# DEFAULT CONFIG
# ============================================================

DOMAIN=""
TARGET_IP=""

MODE="quick"

SKIP_UDP=0
RESUME=0

RATE=10
NMAP_RATE=300

WORDLIST="/usr/share/seclists/Discovery/Web-Content/common.txt"

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

# ============================================================
# FUNCTIONS
# ============================================================

banner() {
    clear 2>/dev/null || true

    echo -e "${CYAN}"
    cat <<'EOF'
     _    _____     _____
    / \  |_ _\ \   / /_ _|
   / _ \  | | \ \ / / | |
  / ___ \ | |  \ V /  | |
 /_/   \_\___|  \_/  |___|   AIVI DARKNET COMMUNITY

       SERVER AUDIT
EOF
    echo -e "${RESET}"

    echo -e "${WHITE}AIVI Server Audit v${VERSION}${RESET}"
    echo
}

info() {
    echo -e "${BLUE}[*]${RESET} $*"
}

success() {
    echo -e "${GREEN}[+]${RESET} $*"
}

warn() {
    echo -e "${YELLOW}[!]${RESET} $*"
}

error() {
    echo -e "${RED}[-]${RESET} $*" >&2
}

section() {
    echo
    echo -e "${CYAN}============================================================${RESET}"
    echo -e "${WHITE}$*${RESET}"
    echo -e "${CYAN}============================================================${RESET}"
}

usage() {

cat <<EOF

AIVI Server Audit v${VERSION}

Usage:

  sudo ./aivi-server-audit.sh --domain example.com [options]

Options:

  --domain DOMAIN
      Authorized domain

  --ip IP
      Authorized server IP

  --quick
      Faster assessment

  --full
      More comprehensive assessment

  --web-only
      Only web-related assessment

  --skip-udp
      Disable UDP scanning

  --rate NUMBER
      Nuclei/content discovery rate
      Default: 10

  --nmap-rate NUMBER
      Maximum packet rate for full TCP discovery
      Default: 300

  --wordlist FILE
      Content-discovery wordlist

  --resume
      Skip stages whose result files already exist

  -h, --help
      Show this menu


Examples:

  ./aivi-server-audit.sh --domain example.com --quick

  sudo ./aivi-server-audit.sh \\
      --domain example.com \\
      --ip 203.0.113.10 \\
      --full

  ./aivi-server-audit.sh \\
      --domain example.com \\
      --web-only \\
      --rate 5

  sudo ./aivi-server-audit.sh \\
      --domain example.com \\
      --ip 203.0.113.10 \\
      --full \\
      --skip-udp \\
      --resume

EOF
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_live() {

    local outfile="$1"
    shift

    if [[ "$RESUME" -eq 1 && -s "$outfile" ]]; then
        warn "Resume: already exists -> $outfile"
        return
    fi

    mkdir -p "$(dirname "$outfile")"

    echo
    echo -e "${DIM}Command: $*${RESET}"
    echo

    "$@" 2>&1 | tee "$outfile"

    local rc=${PIPESTATUS[0]}

    if [[ "$rc" -eq 0 ]]; then
        success "Saved: $outfile"
    else
        warn "Command exited with status $rc"
    fi
}

resolve_ip() {

    if [[ -n "$TARGET_IP" ]]; then
        return
    fi

    info "Resolving IP address..."

    if command_exists dig; then

        TARGET_IP="$(
            dig +short A "$DOMAIN" |
            grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' |
            head -n1
        )"

    fi

    if [[ -z "$TARGET_IP" ]] && command_exists getent; then

        TARGET_IP="$(
            getent ahostsv4 "$DOMAIN" 2>/dev/null |
            awk 'NR==1 {print $1}'
        )"

    fi

    if [[ -n "$TARGET_IP" ]]; then
        success "Resolved $DOMAIN -> $TARGET_IP"
    else
        warn "Could not determine IPv4 address."
    fi
}

# ============================================================
# ARGUMENT PARSER
# ============================================================

while [[ $# -gt 0 ]]; do

    case "$1" in

        --domain)
            DOMAIN="${2:-}"
            shift 2
            ;;

        --ip)
            TARGET_IP="${2:-}"
            shift 2
            ;;

        --quick)
            MODE="quick"
            shift
            ;;

        --full)
            MODE="full"
            shift
            ;;

        --web-only)
            MODE="web"
            shift
            ;;

        --skip-udp)
            SKIP_UDP=1
            shift
            ;;

        --rate)
            RATE="${2:-10}"
            shift 2
            ;;

        --nmap-rate)
            NMAP_RATE="${2:-300}"
            shift 2
            ;;

        --wordlist)
            WORDLIST="${2:-}"
            shift 2
            ;;

        --resume)
            RESUME=1
            shift
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;

    esac

done

# ============================================================
# VALIDATION
# ============================================================

banner

if [[ -z "$DOMAIN" ]]; then
    error "--domain is required."
    echo
    usage
    exit 1
fi

if [[ ! "$DOMAIN" =~ ^[A-Za-z0-9.-]+$ ]]; then
    error "Invalid domain."
    exit 1
fi

if [[ ! "$RATE" =~ ^[0-9]+$ ]]; then
    error "--rate must be numeric."
    exit 1
fi

if [[ ! "$NMAP_RATE" =~ ^[0-9]+$ ]]; then
    error "--nmap-rate must be numeric."
    exit 1
fi

# ============================================================
# OUTPUT DIRECTORIES
# ============================================================

SAFE_DOMAIN="${DOMAIN//[^A-Za-z0-9._-]/_}"

BASE="aivi-results/${SAFE_DOMAIN}"

mkdir -p \
    "$BASE/dns" \
    "$BASE/subdomains" \
    "$BASE/http" \
    "$BASE/ports" \
    "$BASE/services" \
    "$BASE/tls" \
    "$BASE/content" \
    "$BASE/vulnerabilities" \
    "$BASE/exposures" \
    "$BASE/logs" \
    "$BASE/evidence"

LOG="$BASE/logs/run_${TIMESTAMP}.log"

exec > >(tee -a "$LOG") 2>&1

echo "Domain      : $DOMAIN"
echo "Mode        : $MODE"
echo "Rate        : $RATE"
echo "Nmap rate   : $NMAP_RATE"
echo "Skip UDP    : $SKIP_UDP"
echo "Resume      : $RESUME"
echo "Results     : $BASE"
echo

# ============================================================
# DEPENDENCY CHECK
# ============================================================

section "[0] DEPENDENCY CHECK"

TOOLS=(
    dig
    host
    curl
    openssl
    nmap
    subfinder
    assetfinder
    httpx
    nuclei
    nikto
    whatweb
    ffuf
    gobuster
    feroxbuster
)

for tool in "${TOOLS[@]}"; do

    if command_exists "$tool"; then
        printf "${GREEN}[OK]${RESET}   %-20s %s\n" \
            "$tool" "$(command -v "$tool")"
    else
        printf "${YELLOW}[MISS]${RESET} %-20s\n" "$tool"
    fi

done

resolve_ip

echo "Resolved IP : ${TARGET_IP:-UNKNOWN}"

# ============================================================
# DNS
# ============================================================

section "[1] DNS ENUMERATION"

if command_exists dig; then

    {
        echo "===== A ====="
        dig "$DOMAIN" A

        echo
        echo "===== AAAA ====="
        dig "$DOMAIN" AAAA

        echo
        echo "===== NS ====="
        dig "$DOMAIN" NS

        echo
        echo "===== MX ====="
        dig "$DOMAIN" MX

        echo
        echo "===== TXT ====="
        dig "$DOMAIN" TXT

        echo
        echo "===== SOA ====="
        dig "$DOMAIN" SOA

    } | tee "$BASE/dns/dig.txt"

fi

if command_exists host; then
    host "$DOMAIN" 2>&1 |
        tee "$BASE/dns/host.txt"
fi

# ============================================================
# SUBDOMAIN ENUMERATION
# ============================================================

section "[2] SUBDOMAIN DISCOVERY"

if command_exists subfinder; then

    if [[ "$MODE" == "full" ]]; then

        run_live \
            "$BASE/subdomains/subfinder.txt" \
            subfinder \
            -d "$DOMAIN" \
            -all \
            -recursive

    else

        run_live \
            "$BASE/subdomains/subfinder.txt" \
            subfinder \
            -d "$DOMAIN" \
            -silent

    fi

fi

if command_exists assetfinder; then

    info "Running assetfinder..."

    assetfinder --subs-only "$DOMAIN" 2>&1 |
        tee "$BASE/subdomains/assetfinder.txt"

fi

cat "$BASE"/subdomains/*.txt 2>/dev/null |
    grep -E "([A-Za-z0-9_-]+\.)+${DOMAIN//./\\.}$" |
    sort -u \
    > "$BASE/subdomains/all.txt"

SUB_COUNT="$(wc -l < "$BASE/subdomains/all.txt" 2>/dev/null || echo 0)"

success "Unique subdomains: $SUB_COUNT"

# ============================================================
# HTTP DISCOVERY
# ============================================================

section "[3] HTTP / HTTPS DISCOVERY"

if command_exists httpx &&
   [[ -s "$BASE/subdomains/all.txt" ]]; then

    run_live \
        "$BASE/http/live.txt" \
        httpx \
        -l "$BASE/subdomains/all.txt" \
        -status-code \
        -title \
        -tech-detect \
        -web-server \
        -ip \
        -content-length \
        -follow-redirects

    if [[ ! "$RESUME" -eq 1 ||
          ! -s "$BASE/http/live.json" ]]; then

        httpx \
            -l "$BASE/subdomains/all.txt" \
            -status-code \
            -title \
            -tech-detect \
            -web-server \
            -ip \
            -json \
            -silent \
            > "$BASE/http/live.json"

    fi

fi

# ============================================================
# HTTP HEADERS
# ============================================================

section "[4] HTTP HEADERS"

curl -skI \
    --connect-timeout 10 \
    "https://$DOMAIN/" 2>&1 |
    tee "$BASE/http/headers.txt"

echo
info "Security-related headers"

grep -Ei \
'server:|strict-transport-security:|content-security-policy:|x-frame-options:|x-content-type-options:|referrer-policy:|permissions-policy:|set-cookie:' \
"$BASE/http/headers.txt" || true

# ============================================================
# TECHNOLOGY DETECTION
# ============================================================

section "[5] TECHNOLOGY DETECTION"

if command_exists whatweb; then

    run_live \
        "$BASE/http/whatweb.txt" \
        whatweb \
        "https://$DOMAIN/"

fi

# ============================================================
# WEB-ONLY MODE
# ============================================================

if [[ "$MODE" != "web" && -n "$TARGET_IP" ]]; then

    # ========================================================
    # TCP PORTS
    # ========================================================

    section "[6] TCP PORT DISCOVERY"

    if command_exists nmap; then

        if [[ "$MODE" == "full" ]]; then

            run_live \
                "$BASE/ports/all-tcp.txt" \
                nmap \
                -Pn \
                -p- \
                --max-rate "$NMAP_RATE" \
                "$TARGET_IP"

        else

            run_live \
                "$BASE/ports/quick.txt" \
                nmap \
                -Pn \
                --top-ports 1000 \
                "$TARGET_IP"

        fi

        # ====================================================
        # SERVICE IDENTIFICATION
        # ====================================================

        section "[7] SERVICE / VERSION IDENTIFICATION"

        run_live \
            "$BASE/services/versions.txt" \
            nmap \
            -Pn \
            -sV \
            --version-light \
            "$TARGET_IP"

        # ====================================================
        # COMMON SERVICE ENUMERATION
        # ====================================================

        section "[8] COMMON SERVER SERVICES"

        run_live \
            "$BASE/services/common-services.txt" \
            nmap \
            -Pn \
            -sV \
            -p 21,22,25,53,80,110,143,443,465,587,993,995,3306,5432,8080,8443 \
            "$TARGET_IP"

        # ====================================================
        # WEB NMAP
        # ====================================================

        section "[9] HTTP SERVICE ENUMERATION"

        run_live \
            "$BASE/services/http-nmap.txt" \
            nmap \
            -Pn \
            -p80,443,8080,8443 \
            --script http-title,http-headers,http-methods \
            "$TARGET_IP"

        # ====================================================
        # SSH
        # ====================================================

        section "[10] SSH CONFIGURATION"

        run_live \
            "$BASE/services/ssh.txt" \
            nmap \
            -Pn \
            -p22 \
            -sV \
            --script ssh2-enum-algos,ssh-hostkey \
            "$TARGET_IP"

        # ====================================================
        # FTP
        # ====================================================

        section "[11] FTP"

        run_live \
            "$BASE/services/ftp.txt" \
            nmap \
            -Pn \
            -p21 \
            -sV \
            --script ftp-syst \
            "$TARGET_IP"

        # ====================================================
        # SMTP
        # ====================================================

        section "[12] SMTP"

        run_live \
            "$BASE/services/smtp.txt" \
            nmap \
            -Pn \
            -p25,465,587 \
            -sV \
            --script smtp-commands \
            "$TARGET_IP"

        # ====================================================
        # DNS
        # ====================================================

        section "[13] DNS SERVICE"

        run_live \
            "$BASE/services/dns.txt" \
            nmap \
            -Pn \
            -p53 \
            -sV \
            --script dns-nsid \
            "$TARGET_IP"

        # ====================================================
        # UDP
        # ====================================================

        if [[ "$SKIP_UDP" -eq 0 ]]; then

            section "[14] UDP DISCOVERY"

            if [[ "$EUID" -ne 0 ]]; then

                warn "UDP SYN/raw-packet scanning generally needs root."
                warn "Run with sudo for this stage."

            else

                if [[ "$MODE" == "full" ]]; then
                    UDP_PORTS=100
                else
                    UDP_PORTS=20
                fi

                run_live \
                    "$BASE/ports/udp.txt" \
                    nmap \
                    -Pn \
                    -sU \
                    --top-ports "$UDP_PORTS" \
                    -sV \
                    "$TARGET_IP"

            fi

        else
            warn "UDP scanning disabled."
        fi

    fi

fi

# ============================================================
# TLS
# ============================================================

section "[15] TLS / SSL"

if command_exists openssl; then

    info "Retrieving certificate..."

    openssl s_client \
        -connect "$DOMAIN:443" \
        -servername "$DOMAIN" \
        </dev/null 2>/dev/null |
    openssl x509 \
        -noout \
        -subject \
        -issuer \
        -serial \
        -dates \
        -fingerprint \
        -sha256 2>&1 |
    tee "$BASE/tls/certificate.txt"

fi

if command_exists nmap && [[ -n "$TARGET_IP" ]]; then

    run_live \
        "$BASE/tls/nmap-tls.txt" \
        nmap \
        -Pn \
        -p443 \
        --script ssl-cert,ssl-enum-ciphers \
        "$TARGET_IP"

fi

if command_exists testssl.sh; then

    run_live \
        "$BASE/tls/testssl.txt" \
        testssl.sh \
        --quiet \
        "https://$DOMAIN"

fi

# ============================================================
# STANDARD EXPOSURE CHECKS
# ============================================================

section "[16] STANDARD WEB FILES"

for path in \
    robots.txt \
    sitemap.xml \
    .well-known/security.txt
do

    safe_name="${path//\//_}"

    echo
    info "/$path"

    curl -sk \
        --max-time 15 \
        "https://$DOMAIN/$path" 2>&1 |
        tee "$BASE/exposures/${safe_name}.txt"

done

# ============================================================
# NUCLEI
# ============================================================

section "[17] NUCLEI"

if command_exists nuclei; then

    run_live \
        "$BASE/vulnerabilities/nuclei.txt" \
        nuclei \
        -u "https://$DOMAIN" \
        -severity info,low,medium,high,critical \
        -rate-limit "$RATE"

    if [[ "$MODE" == "full" ]]; then

        run_live \
            "$BASE/vulnerabilities/nuclei-misconfig.txt" \
            nuclei \
            -u "https://$DOMAIN" \
            -tags misconfig \
            -rate-limit "$RATE"

        run_live \
            "$BASE/vulnerabilities/nuclei-exposure.txt" \
            nuclei \
            -u "https://$DOMAIN" \
            -tags exposure \
            -rate-limit "$RATE"

    fi

fi

# ============================================================
# NIKTO
# ============================================================

section "[18] NIKTO"

if command_exists nikto; then

    run_live \
        "$BASE/vulnerabilities/nikto.txt" \
        nikto \
        -h "https://$DOMAIN"

fi

# ============================================================
# CONTENT DISCOVERY
# ============================================================

section "[19] CONTENT DISCOVERY"

if [[ ! -f "$WORDLIST" ]]; then

    warn "Wordlist not found:"
    warn "$WORDLIST"

else

    if command_exists ffuf; then

        info "FFUF"

        ffuf \
            -u "https://$DOMAIN/FUZZ" \
            -w "$WORDLIST" \
            -mc 200,204,301,302,307,401,403 \
            -t "$RATE" \
            -of json \
            -o "$BASE/content/ffuf.json"

    fi

    if [[ "$MODE" == "full" ]]; then

        if command_exists gobuster; then

            run_live \
                "$BASE/content/gobuster.txt" \
                gobuster dir \
                -u "https://$DOMAIN/" \
                -w "$WORDLIST" \
                -t "$RATE"

        fi

        if command_exists feroxbuster; then

            run_live \
                "$BASE/content/feroxbuster.txt" \
                feroxbuster \
                -u "https://$DOMAIN/" \
                -w "$WORDLIST" \
                -t "$RATE"

        fi

    fi

fi

# ============================================================
# NMAP VULNERABILITY INDICATORS
# ============================================================

if [[ "$MODE" == "full" &&
      -n "$TARGET_IP" &&
      "$MODE" != "web" ]] &&
   command_exists nmap; then

    section "[20] NMAP VULNERABILITY INDICATORS"

    warn "This stage sends active vulnerability-check requests."

    run_live \
        "$BASE/vulnerabilities/nmap-vuln.txt" \
        nmap \
        -Pn \
        -sV \
        --script vuln \
        "$TARGET_IP"

fi

# ============================================================
# SUMMARY
# ============================================================

section "[21] GENERATING SUMMARY"

SUMMARY="$BASE/summary.txt"

{
    echo "============================================================"
    echo "AIVI SERVER AUDIT"
    echo "============================================================"
    echo

    echo "Version       : $VERSION"
    echo "Date          : $(date)"
    echo "Domain        : $DOMAIN"
    echo "IP            : ${TARGET_IP:-UNKNOWN}"
    echo "Mode          : $MODE"
    echo "Rate          : $RATE"
    echo "Nmap rate     : $NMAP_RATE"

    echo
    echo "---------------- SUBDOMAINS ----------------"
    echo

    if [[ -f "$BASE/subdomains/all.txt" ]]; then
        cat "$BASE/subdomains/all.txt"
    fi

    echo
    echo "---------------- HTTP SERVICES -------------"
    echo

    if [[ -f "$BASE/http/live.txt" ]]; then
        cat "$BASE/http/live.txt"
    fi

    echo
    echo "---------------- NUCLEI --------------------"
    echo

    if [[ -f "$BASE/vulnerabilities/nuclei.txt" ]]; then
        cat "$BASE/vulnerabilities/nuclei.txt"
    fi

    echo
    echo "---------------- NIKTO ---------------------"
    echo

    if [[ -f "$BASE/vulnerabilities/nikto.txt" ]]; then
        cat "$BASE/vulnerabilities/nikto.txt"
    fi

    echo
    echo "============================================================"
    echo "RESULT DIRECTORY"
    echo "$BASE"
    echo "============================================================"

} > "$SUMMARY"

# ============================================================
# FINISH
# ============================================================

section "ASSESSMENT COMPLETE"

success "Domain: $DOMAIN"

if [[ -n "$TARGET_IP" ]]; then
    success "IP: $TARGET_IP"
fi

success "Results: $BASE"
success "Summary: $SUMMARY"
success "Log: $LOG"

echo
echo -e "${YELLOW}Scanner findings are candidates, not proof of vulnerability.${RESET}"
echo -e "${YELLOW}Manually validate findings before assigning severity.${RESET}"
echo
