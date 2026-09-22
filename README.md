# AIVI-Server-Audit-v1.0
<div align="center">

# ⚡ AIVI SERVER AUDIT v1.0

```text
     _    _____     _____
    / \  |_ _\ \   / /_ _|
   / _ \  | | \ \ / / | |
  / ___ \ | |  \ V /  | |
 /_/   \_\___|  \_/  |___|

        SERVER AUDIT
       VERSION 1.0.0
```

### Automated Server & Web Security Assessment Orchestrator

**Recon • DNS • HTTP • Network • TLS • Vulnerability Scanning • Reporting**

![Bash](https://img.shields.io/badge/Bash-Linux-black?style=for-the-badge&logo=gnu-bash)
![Kali Linux](https://img.shields.io/badge/Kali-Linux-blue?style=for-the-badge&logo=kalilinux)
![Version](https://img.shields.io/badge/Version-1.0.0-green?style=for-the-badge)
![Security](https://img.shields.io/badge/Use-Authorized%20Testing-red?style=for-the-badge)

</div>

---

## `[+] ABOUT`

**AIVI Server Audit** is a Bash-based security assessment orchestrator designed to automate common server and web security auditing tasks.

Instead of manually executing multiple reconnaissance, network, HTTP, TLS and vulnerability-scanning commands, AIVI organizes them into a repeatable assessment workflow with live terminal output and structured result storage.

```text
TARGET
  │
  ├── DNS Enumeration
  │
  ├── Subdomain Discovery
  │
  ├── HTTP/HTTPS Discovery
  │
  ├── Technology Detection
  │
  ├── TCP/UDP Discovery
  │
  ├── Service Identification
  │
  ├── TLS Analysis
  │
  ├── Exposure Checks
  │
  ├── Vulnerability Scanning
  │
  └── Result / Evidence Collection
```

> [!WARNING]
> Run AIVI Server Audit only against systems that you own or have explicit authorization to test.

---

# `[+] FEATURES`

```text
[✓] DNS enumeration
[✓] Passive subdomain discovery
[✓] Live HTTP/HTTPS discovery
[✓] HTTP technology fingerprinting
[✓] HTTP security-header inspection
[✓] TCP port discovery
[✓] Service/version identification
[✓] Controlled UDP discovery
[✓] TLS certificate inspection
[✓] TLS cipher analysis
[✓] Standard exposure checks
[✓] Nuclei integration
[✓] Nikto integration
[✓] Content discovery
[✓] Live terminal output
[✓] Structured evidence directories
[✓] Resume support
[✓] Rate controls
```

---

# `[+] TOOLCHAIN`

AIVI integrates with common security utilities:

```text
┌────────────────────┬──────────────────────────────┐
│ TOOL               │ PURPOSE                      │
├────────────────────┼──────────────────────────────┤
│ dig / host         │ DNS intelligence             │
│ subfinder          │ Passive subdomain discovery  │
│ assetfinder        │ Asset discovery              │
│ httpx              │ HTTP service discovery       │
│ curl               │ HTTP/header inspection       │
│ WhatWeb            │ Technology fingerprinting    │
│ Nmap               │ Ports/services/network       │
│ OpenSSL            │ TLS certificate inspection   │
│ testssl.sh         │ TLS configuration analysis   │
│ Nuclei             │ Template security checks     │
│ Nikto              │ Web server assessment        │
│ FFUF                │ Content discovery            │
│ Gobuster           │ Content discovery            │
│ Feroxbuster        │ Recursive discovery          │
└────────────────────┴──────────────────────────────┘
```

---

# `[+] INSTALLATION`

### 1. Clone

```bash
git clone YOUR-GITHUB-REPOSITORY-URL
cd AIVI-Server-Audit
```

### 2. Make executable

```bash
chmod +x aivi-server-audit.sh
```

### 3. Verify Bash syntax

```bash
bash -n aivi-server-audit.sh
```

Expected:

```text
No output = syntax OK
```

---

# `[+] USAGE`

```bash
bash ./aivi-server-audit.sh --domain example.com --quick
```

Display help:

```bash
bash ./aivi-server-audit.sh --help
```

---

## `[01] QUICK ASSESSMENT`

```bash
bash ./aivi-server-audit.sh --domain example.com --quick
```

Designed for faster initial assessment.

---

## `[02] FULL ASSESSMENT`

```bash
sudo bash ./aivi-server-audit.sh \
  --domain example.com \
  --ip 203.0.113.10 \
  --full
```

> Replace the example domain/IP with an authorized target.

---

## `[03] WEB-ONLY ASSESSMENT`

```bash
bash ./aivi-server-audit.sh \
  --domain example.com \
  --web-only
```

---

## `[04] CONSERVATIVE FULL ASSESSMENT`

```bash
sudo bash ./aivi-server-audit.sh \
  --domain example.com \
  --ip 203.0.113.10 \
  --full \
  --skip-udp \
  --rate 5 \
  --nmap-rate 200
```

---

## `[05] RESUME`

If an assessment is interrupted:

```bash
sudo bash ./aivi-server-audit.sh \
  --domain example.com \
  --ip 203.0.113.10 \
  --full \
  --resume
```

---

# `[+] OPTIONS`

```text
--domain DOMAIN
    Authorized domain to assess

--ip IP
    Authorized server IP

--quick
    Faster assessment

--full
    More comprehensive assessment

--web-only
    Web-focused assessment

--skip-udp
    Disable UDP discovery

--rate NUMBER
    Request-rate control

--nmap-rate NUMBER
    Nmap packet-rate control

--wordlist FILE
    Content-discovery wordlist

--resume
    Resume previously generated results

-h, --help
    Display help
```

---

# `[+] TERMINAL PREVIEW`

```text
     _    _____     _____
    / \  |_ _\ \   / /_ _|
   / _ \  | | \ \ / / | |
  / ___ \ | |  \ V /  | |
 /_/   \_\___|  \_/  |___|

        SERVER AUDIT

AIVI Server Audit v1.0.0

============================================================
[0] DEPENDENCY CHECK
============================================================

[OK]   dig
[OK]   curl
[OK]   openssl
[OK]   nmap
[OK]   subfinder
[OK]   assetfinder
[OK]   httpx
[OK]   nuclei
[OK]   nikto
[OK]   whatweb
[OK]   ffuf

============================================================
[1] DNS ENUMERATION
============================================================

[*] Resolving target...
[+] DNS results saved

============================================================
[2] SUBDOMAIN DISCOVERY
============================================================

[*] Running Subfinder...
[*] Running Assetfinder...
[+] Unique subdomains collected

============================================================
[3] HTTP / HTTPS DISCOVERY
============================================================

[*] Probing discovered hosts...
[+] HTTP inventory generated

============================================================
[6] TCP PORT DISCOVERY
============================================================

[*] Running network discovery...
[+] Results saved

============================================================
[15] TLS / SSL
============================================================

[*] Retrieving certificate...
[+] TLS evidence saved

============================================================
[17] NUCLEI
============================================================

[*] Running template checks...
[+] Results saved

============================================================
ASSESSMENT COMPLETE
============================================================

[+] Results: aivi-results/example.com
[+] Summary: aivi-results/example.com/summary.txt
```

---

# `[+] OUTPUT STRUCTURE`

```text
aivi-results/
└── example.com/
    ├── dns/
    ├── subdomains/
    ├── http/
    ├── ports/
    ├── services/
    ├── tls/
    ├── content/
    ├── vulnerabilities/
    ├── exposures/
    ├── evidence/
    ├── logs/
    └── summary.txt
```

The original v1.0 implementation separates DNS, subdomain, HTTP, ports, services, TLS, content, vulnerability, exposure, logs and evidence results. 

---

# `[+] SECURITY MODEL`

AIVI Server Audit is intended for:

```text
[+] Systems you own
[+] Authorized penetration testing
[+] Security research labs
[+] CTF/lab environments
[+] Defensive security assessments
[+] Bug-bounty targets within published scope
```

It is **not authorization to test a system**.

The operator is responsible for confirming scope and authorization before running the tool.

---

# `[+] FINDING VALIDATION`

```text
Scanner Result
      │
      ▼
Candidate Finding
      │
      ▼
Manual Validation
      │
      ▼
Evidence + Impact
      │
      ▼
Remediation
```

Automated scanner output should not automatically be treated as proof of a vulnerability.

---

# `[+] PROJECT STATUS`

```text
PROJECT : AIVI Server Audit
VERSION : 1.0.0
LANGUAGE: Bash
PLATFORM: Linux / Kali Linux
STATUS  : Active Development
```

---

# `[+] ROADMAP`

```text
[✓] v1.0 — Core server audit
[ ] Improved scope engine
[ ] Multi-host workflow
[ ] Finding normalization
[ ] JSON reporting
[ ] HTML dashboard
[ ] Historical comparison
[ ] Plugin architecture
```

---

# `[+] CONTRIBUTING`

Bug reports and improvements are welcome.

Before submitting changes:

```bash
bash -n aivi-server-audit.sh
```

Keep new assessment modules:

- scope-aware
- rate-controlled
- reproducible
- evidence-oriented
- non-destructive by default

---

# `[+] DISCLAIMER`

This project is intended for legitimate cybersecurity education, defensive security research, and authorized security assessment.

You are responsible for obtaining appropriate authorization before testing any system.

---

<div align="center">

```text
╔══════════════════════════════════════════════╗
║                                              ║
║             AIVI SERVER AUDIT                ║
║                  v1.0.0                      ║
║                                              ║
║      RECON • ANALYZE • VERIFY • REPORT       ║
║                                              ║
╚══════════════════════════════════════════════╝
```

**AIVI DARKNET COMMUNITY**

*Cybersecurity • Security Research • OSINT • Bug Bounty*

</div>
