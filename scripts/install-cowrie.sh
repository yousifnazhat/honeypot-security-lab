#!/bin/bash
# ============================================================================
# Cowrie SSH Honeypot Installation Script
# Virtual Honeypot Security Monitoring Lab
# ============================================================================
# Run this script on the Ubuntu Server VM designated as the honeypot host.
# Requires: Ubuntu 22.04+, root/sudo access, internet connection
# ============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

COWRIE_USER="cowrie"
COWRIE_DIR="/opt/cowrie"
COWRIE_LOG_DIR="/var/log/cowrie"
ELK_SERVER_IP="10.0.0.30"

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Cowrie SSH Honeypot Installer${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# --- Check root ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run as root (sudo)${NC}"
    exit 1
fi

# --- Step 1: Install Dependencies ---
echo -e "${YELLOW}[1/6] Installing system dependencies...${NC}"
apt-get update -qq
apt-get install -y -qq \
    git python3 python3-venv python3-pip \
    libssl-dev libffi-dev build-essential \
    python3-dev authbind iptables

echo -e "${GREEN}  [✓] Dependencies installed${NC}"

# --- Step 2: Create Cowrie User ---
echo -e "${YELLOW}[2/6] Creating cowrie user...${NC}"
if ! id "$COWRIE_USER" &>/dev/null; then
    adduser --disabled-password --gecos "" $COWRIE_USER
    echo -e "${GREEN}  [✓] User '${COWRIE_USER}' created${NC}"
else
    echo -e "${GREEN}  [✓] User '${COWRIE_USER}' already exists${NC}"
fi

# --- Step 3: Clone Cowrie ---
echo -e "${YELLOW}[3/6] Cloning Cowrie repository...${NC}"
if [ ! -d "$COWRIE_DIR" ]; then
    git clone https://github.com/cowrie/cowrie.git $COWRIE_DIR
    chown -R $COWRIE_USER:$COWRIE_USER $COWRIE_DIR
    echo -e "${GREEN}  [✓] Cowrie cloned to ${COWRIE_DIR}${NC}"
else
    echo -e "${GREEN}  [✓] Cowrie already exists at ${COWRIE_DIR}${NC}"
fi

# --- Step 4: Setup Python Virtual Environment ---
echo -e "${YELLOW}[4/6] Setting up Python virtual environment...${NC}"
sudo -u $COWRIE_USER bash -c "
    cd $COWRIE_DIR
    python3 -m venv cowrie-env
    source cowrie-env/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
"
echo -e "${GREEN}  [✓] Virtual environment configured${NC}"

# --- Step 5: Configure Cowrie ---
echo -e "${YELLOW}[5/6] Applying Cowrie configuration...${NC}"

# Create log directory
mkdir -p $COWRIE_LOG_DIR
chown $COWRIE_USER:$COWRIE_USER $COWRIE_LOG_DIR

# Copy custom config if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="${SCRIPT_DIR}/../configs/cowrie/cowrie.cfg"

if [ -f "$CONFIG_SRC" ]; then
    cp "$CONFIG_SRC" "${COWRIE_DIR}/etc/cowrie.cfg"
    chown $COWRIE_USER:$COWRIE_USER "${COWRIE_DIR}/etc/cowrie.cfg"
    echo -e "${GREEN}  [✓] Custom configuration applied${NC}"
else
    cp "${COWRIE_DIR}/etc/cowrie.cfg.dist" "${COWRIE_DIR}/etc/cowrie.cfg"
    echo -e "${YELLOW}  [!] Using default config (custom config not found)${NC}"
fi

# --- Step 6: Configure Port Forwarding ---
echo -e "${YELLOW}[6/6] Setting up port forwarding (22 → 2222)...${NC}"
iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
iptables -t nat -A PREROUTING -p tcp --dport 23 -j REDIRECT --to-port 2223

# Save iptables rules
iptables-save > /etc/iptables.rules
echo "#!/bin/sh" > /etc/network/if-pre-up.d/iptables
echo "iptables-restore < /etc/iptables.rules" >> /etc/network/if-pre-up.d/iptables
chmod +x /etc/network/if-pre-up.d/iptables

echo -e "${GREEN}  [✓] Port forwarding configured${NC}"
echo "  SSH  (22) → Cowrie (2222)"
echo "  Telnet (23) → Cowrie (2223)"
echo ""

# --- Start Cowrie ---
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Starting Cowrie Honeypot${NC}"
echo -e "${CYAN}============================================${NC}"
sudo -u $COWRIE_USER bash -c "
    cd $COWRIE_DIR
    source cowrie-env/bin/activate
    bin/cowrie start
"

echo ""
echo -e "${GREEN}[✓] Cowrie SSH Honeypot is now running!${NC}"
echo ""
echo "  Logs: ${COWRIE_LOG_DIR}/cowrie.json"
echo "  Config: ${COWRIE_DIR}/etc/cowrie.cfg"
echo ""
echo "  To check status:  sudo -u cowrie ${COWRIE_DIR}/bin/cowrie status"
echo "  To stop:           sudo -u cowrie ${COWRIE_DIR}/bin/cowrie stop"
echo "  To view live logs: tail -f ${COWRIE_DIR}/var/log/cowrie/cowrie.json"
