#!/bin/bash
# ============================================================================
# VirtualBox VM Setup Script
# Virtual Honeypot Security Monitoring Lab
# ============================================================================
# This script provides step-by-step guidance for setting up VirtualBox VMs
# for the honeypot lab environment.
# ============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Honeypot Lab - VM Setup Guide${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# --- Check for VirtualBox ---
if ! command -v VBoxManage &> /dev/null; then
    echo -e "${RED}[ERROR] VirtualBox is not installed.${NC}"
    echo "Download from: https://www.virtualbox.org/wiki/Downloads"
    exit 1
fi

VBOX_VERSION=$(VBoxManage --version)
echo -e "${GREEN}[✓] VirtualBox detected: v${VBOX_VERSION}${NC}"
echo ""

# --- Network Configuration ---
NETWORK_NAME="honeypot-intnet"

echo -e "${YELLOW}[1/4] Configuring Internal Network...${NC}"
echo "  Network Name: ${NETWORK_NAME}"
echo "  Subnet: 10.0.0.0/24"
echo ""

# --- VM: Ubuntu Server (Honeypot) ---
VM_HONEYPOT="Honeypot-Ubuntu"
echo -e "${YELLOW}[2/4] Creating Ubuntu Server VM (Honeypot Host)...${NC}"

VBoxManage createvm --name "$VM_HONEYPOT" --ostype "Ubuntu_64" --register 2>/dev/null || true
VBoxManage modifyvm "$VM_HONEYPOT" \
    --memory 2048 \
    --cpus 2 \
    --vram 16 \
    --nic1 nat \
    --nic2 intnet \
    --intnet2 "$NETWORK_NAME" \
    --boot1 dvd \
    --boot2 disk 2>/dev/null || true

VBoxManage createhd --filename "${HOME}/VirtualBox VMs/${VM_HONEYPOT}/${VM_HONEYPOT}.vdi" \
    --size 20480 --format VDI 2>/dev/null || true

echo -e "${GREEN}  [✓] VM '${VM_HONEYPOT}' configured${NC}"
echo "  RAM: 2GB | CPU: 2 cores | Disk: 20GB"
echo "  NIC1: NAT (internet) | NIC2: Internal (${NETWORK_NAME})"
echo ""

# --- VM: Kali Linux (Attacker) ---
VM_ATTACKER="Attacker-Kali"
echo -e "${YELLOW}[3/4] Creating Kali Linux VM (Attacker)...${NC}"

VBoxManage createvm --name "$VM_ATTACKER" --ostype "Debian_64" --register 2>/dev/null || true
VBoxManage modifyvm "$VM_ATTACKER" \
    --memory 2048 \
    --cpus 2 \
    --vram 128 \
    --nic1 nat \
    --nic2 intnet \
    --intnet2 "$NETWORK_NAME" \
    --boot1 dvd \
    --boot2 disk 2>/dev/null || true

VBoxManage createhd --filename "${HOME}/VirtualBox VMs/${VM_ATTACKER}/${VM_ATTACKER}.vdi" \
    --size 30720 --format VDI 2>/dev/null || true

echo -e "${GREEN}  [✓] VM '${VM_ATTACKER}' configured${NC}"
echo "  RAM: 2GB | CPU: 2 cores | Disk: 30GB"
echo "  NIC1: NAT (internet) | NIC2: Internal (${NETWORK_NAME})"
echo ""

# --- VM: ELK Server (SIEM) ---
VM_SIEM="SIEM-ELK"
echo -e "${YELLOW}[4/4] Creating ELK Server VM (SIEM)...${NC}"

VBoxManage createvm --name "$VM_SIEM" --ostype "Ubuntu_64" --register 2>/dev/null || true
VBoxManage modifyvm "$VM_SIEM" \
    --memory 4096 \
    --cpus 2 \
    --vram 16 \
    --nic1 nat \
    --nic2 intnet \
    --intnet2 "$NETWORK_NAME" \
    --boot1 dvd \
    --boot2 disk 2>/dev/null || true

VBoxManage createhd --filename "${HOME}/VirtualBox VMs/${VM_SIEM}/${VM_SIEM}.vdi" \
    --size 40960 --format VDI 2>/dev/null || true

echo -e "${GREEN}  [✓] VM '${VM_SIEM}' configured${NC}"
echo "  RAM: 4GB | CPU: 2 cores | Disk: 40GB"
echo "  NIC1: NAT (internet) | NIC2: Internal (${NETWORK_NAME})"
echo ""

# --- IP Assignment Guide ---
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Static IP Assignment (on each VM)${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo "  After installing the OS on each VM, configure"
echo "  static IPs on the internal network adapter:"
echo ""
echo "  Honeypot (Ubuntu):  10.0.0.10/24"
echo "  Attacker (Kali):    10.0.0.20/24"
echo "  SIEM (ELK):         10.0.0.30/24"
echo ""
echo "  Example (Ubuntu /etc/netplan/01-internal.yaml):"
echo "  ---"
echo "  network:"
echo "    version: 2"
echo "    ethernets:"
echo "      enp0s8:"
echo "        addresses: [10.0.0.10/24]"
echo ""
echo -e "${GREEN}[✓] VM Setup Complete!${NC}"
echo "  Next steps:"
echo "  1. Mount ISOs and install operating systems"
echo "  2. Configure static IPs as shown above"
echo "  3. Run install-cowrie.sh on the Honeypot VM"
echo "  4. Run install-elk.sh on the SIEM VM"
