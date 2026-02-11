#!/bin/bash
# ============================================================================
# ELK Stack Installation Script
# Virtual Honeypot Security Monitoring Lab
# ============================================================================
# Installs Elasticsearch, Logstash, and Kibana on Ubuntu Server.
# Run this on the SIEM VM.
# Requires: Ubuntu 22.04+, root/sudo, 4GB+ RAM, internet connection
# ============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ELK_VERSION="8.x"
HONEYPOT_IP="10.0.0.10"

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  ELK Stack Installer (SIEM Server)${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# --- Check root ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run as root (sudo)${NC}"
    exit 1
fi

# --- Step 1: Install Java ---
echo -e "${YELLOW}[1/5] Installing Java (OpenJDK 17)...${NC}"
apt-get update -qq
apt-get install -y -qq openjdk-17-jdk apt-transport-https curl gnupg
echo -e "${GREEN}  [✓] Java installed${NC}"

# --- Step 2: Add Elastic APT Repository ---
echo -e "${YELLOW}[2/5] Adding Elasticsearch APT repository...${NC}"
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/${ELK_VERSION}/apt stable main" | \
    tee /etc/apt/sources.list.d/elastic-${ELK_VERSION}.list
apt-get update -qq
echo -e "${GREEN}  [✓] Repository added${NC}"

# --- Step 3: Install Elasticsearch ---
echo -e "${YELLOW}[3/5] Installing Elasticsearch...${NC}"
apt-get install -y -qq elasticsearch

# Configure Elasticsearch
cat > /etc/elasticsearch/elasticsearch.yml << 'EOF'
cluster.name: honeypot-siem
node.name: siem-node-1
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
xpack.security.enabled: false
EOF

systemctl daemon-reload
systemctl enable elasticsearch
systemctl start elasticsearch
echo -e "${GREEN}  [✓] Elasticsearch installed and started (port 9200)${NC}"

# --- Step 4: Install Logstash ---
echo -e "${YELLOW}[4/5] Installing Logstash...${NC}"
apt-get install -y -qq logstash

# Copy pipeline config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINE_SRC="${SCRIPT_DIR}/../configs/logstash/cowrie-pipeline.conf"

if [ -f "$PIPELINE_SRC" ]; then
    cp "$PIPELINE_SRC" /etc/logstash/conf.d/cowrie-pipeline.conf
    echo -e "${GREEN}  [✓] Custom Logstash pipeline applied${NC}"
else
    # Create default pipeline
    cat > /etc/logstash/conf.d/cowrie-pipeline.conf << EOF
input {
  file {
    path => "/var/log/cowrie/cowrie.json"
    codec => json
    type => "cowrie"
    start_position => "beginning"
    sincedb_path => "/var/lib/logstash/sincedb_cowrie"
  }
}

filter {
  if [type] == "cowrie" {
    date {
      match => [ "timestamp", "ISO8601" ]
    }
    mutate {
      add_field => { "honeypot_type" => "ssh" }
    }
    if [src_ip] {
      geoip {
        source => "src_ip"
        target => "geoip"
      }
    }
  }
}

output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "cowrie-logs-%{+YYYY.MM.dd}"
  }
  stdout {
    codec => dots
  }
}
EOF
    echo -e "${YELLOW}  [!] Using default pipeline config${NC}"
fi

systemctl daemon-reload
systemctl enable logstash
systemctl start logstash
echo -e "${GREEN}  [✓] Logstash installed and started${NC}"

# --- Step 5: Install Kibana ---
echo -e "${YELLOW}[5/5] Installing Kibana...${NC}"
apt-get install -y -qq kibana

# Configure Kibana
cat > /etc/kibana/kibana.yml << 'EOF'
server.host: "0.0.0.0"
server.port: 5601
server.name: "honeypot-siem-dashboard"
elasticsearch.hosts: ["http://localhost:9200"]
EOF

systemctl daemon-reload
systemctl enable kibana
systemctl start kibana
echo -e "${GREEN}  [✓] Kibana installed and started (port 5601)${NC}"

# --- Summary ---
echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  ELK Stack Installation Complete!${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo "  Services:"
echo "  • Elasticsearch: http://localhost:9200"
echo "  • Kibana:        http://localhost:5601"
echo "  • Logstash:      Listening for Cowrie logs"
echo ""
echo "  Next Steps:"
echo "  1. Ensure Cowrie logs are forwarded to this server"
echo "     (rsync or filebeat from ${HONEYPOT_IP})"
echo "  2. Open Kibana at http://10.0.0.30:5601"
echo "  3. Create index pattern: cowrie-logs-*"
echo "  4. Import dashboard from configs/kibana/dashboard-export.ndjson"
echo ""
echo -e "${GREEN}[✓] SIEM server ready for monitoring!${NC}"
