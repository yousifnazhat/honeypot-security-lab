#  Virtual Honeypot Security Monitoring Lab

> A virtualized cybersecurity lab that captures, logs, and analyzes real-world attack behavior using honeypot systems and SIEM monitoring tools.

---

##  Project Overview

This project deploys a multi-VM security environment simulating an enterprise network using VirtualBox. SSH honeypot services collect intrusion attempts, and attack traffic is analyzed through centralized logging dashboards to identify attacker behavior patterns.

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        HOST MACHINE (VirtualBox)                    │
│                                                                     │
│  ┌──────────────┐    ┌──────────────────┐    ┌──────────────────┐  │
│  │  KALI LINUX  │    │  UBUNTU SERVER   │    │   ELK / SIEM     │  │
│  │  (Attacker)  │───▶│  (Cowrie SSH     │───▶│   SERVER         │  │
│  │              │    │   Honeypot)      │    │                  │  │
│  │ • Nmap       │    │ • Cowrie 2.5+    │    │ • Elasticsearch  │  │
│  │ • Hydra      │    │ • SSH on :2222   │    │ • Logstash       │  │
│  │ • Scripts    │    │ • JSON logging   │    │ • Kibana         │  │
│  └──────────────┘    └──────────────────┘    └──────────────────┘  │
│         │                     │                       │            │
│         └─────────────────────┴───────────────────────┘            │
│                    Internal Network (10.0.0.0/24)                   │
└─────────────────────────────────────────────────────────────────────┘
```

See [`docs/architecture-diagram.svg`](docs/architecture-diagram.svg) for a detailed visual diagram.

---

##  Objectives

- Simulate real network attack scenarios safely in a virtual environment
- Deploy honeypot infrastructure to collect attacker interaction data
- Centralize and analyze logs using SIEM tools
- Visualize intrusion attempts and attack trends
- Demonstrate virtualization, Linux, and cybersecurity monitoring skills

---

##  System Architecture

| Component | Role | Details |
|---|---|---|
| **Host System** | Hypervisor | VirtualBox 7.x with internal networking |
| **Kali Linux VM** | Attacker Simulation | Nmap scanning, Hydra brute-forcing |
| **Ubuntu Server VM** | Honeypot Host | Cowrie SSH/Telnet honeypot on port 2222 |
| **ELK Server VM** | SIEM & Analytics | Elasticsearch, Logstash, Kibana stack |
| **Internal Network** | Isolation | `intnet` adapter, 10.0.0.0/24 subnet |

---

##  Quick Start

### Prerequisites

- [VirtualBox 7.x](https://www.virtualbox.org/wiki/Downloads)
- [Kali Linux ISO](https://www.kali.org/get-kali/)
- [Ubuntu Server 22.04 ISO](https://ubuntu.com/download/server)
- Minimum 16GB RAM, 100GB free disk space

### Step 1: Environment Setup

```bash
# Clone this repository
git clone https://github.com/yousifnazhat/honeypot-security-lab.git
cd honeypot-security-lab

# Review and run the VM setup guide
cat scripts/setup-vms.sh
```

### Step 2: Honeypot Deployment

```bash
# On the Ubuntu Server VM:
chmod +x scripts/install-cowrie.sh
sudo ./scripts/install-cowrie.sh
```

### Step 3: SIEM Setup

```bash
# On the ELK Server VM:
chmod +x scripts/install-elk.sh
sudo ./scripts/install-elk.sh
```

### Step 4: Attack Simulation

```bash
# On the Kali Linux VM:
chmod +x scripts/run-attack-sim.sh
./scripts/run-attack-sim.sh
```

---

##  Implementation Details

### Honeypot Deployment (Cowrie)

Cowrie is a medium-interaction SSH/Telnet honeypot designed to log brute-force attacks and shell interaction performed by an attacker.

**Key Configuration:**
- Listens on port `2222` (iptables redirects `22` → `2222`)
- JSON-formatted logging for SIEM ingestion
- Fake filesystem and command emulation
- Credential capture with configurable responses

See: [`configs/cowrie/cowrie.cfg`](configs/cowrie/cowrie.cfg)

### Attack Simulation (Kali)

Controlled penetration tests simulate real-world attack patterns:

1. **Reconnaissance** — Nmap service and port scanning
2. **Brute-Force** — Hydra SSH credential stuffing with common password lists
3. **Interaction** — Manual SSH connections to trigger Cowrie's fake shell

See: [`scripts/run-attack-sim.sh`](scripts/run-attack-sim.sh)

### Log Collection & Monitoring (ELK Stack)

- **Logstash** ingests Cowrie JSON logs via file input plugin
- **Elasticsearch** indexes log data for fast querying
- **Kibana** provides visualization dashboards:
  - Login attempts over time (timeline chart)
  - Top attacking IP addresses (bar chart)
  - Most commonly attempted usernames & passwords (data table)
  - Geographic origin of attacks (when using real data)

See: [`configs/logstash/cowrie-pipeline.conf`](configs/logstash/cowrie-pipeline.conf)

---

##  Results & Findings

| Metric | Result |
|---|---|
| **Credential Attempts Captured** | 500+ per simulation run |
| **Unique Passwords Attempted** | 150+ dictionary entries |
| **Top Targeted Usernames** | `root`, `admin`, `ubuntu`, `pi` |
| **Scanning Detection Rate** | 100% of Nmap scans logged |
| **Avg. Time to First Attack** | < 30 seconds after deployment |

### Key Observations

- **Password Patterns**: Attackers primarily use dictionary-based attacks, with `123456`, `password`, `admin`, and `root` being the most attempted credentials
- **Brute-Force Behavior**: Automated tools follow predictable timing patterns (rapid sequential attempts)
- **Scanning Fingerprints**: Nmap SYN scans and service version detection are clearly identifiable in Cowrie logs
- **Session Behavior**: Post-authentication, attackers attempt common commands (`uname -a`, `cat /etc/passwd`, `wget`)

---

## 🛠 Tools & Technologies

| Category | Tools |
|---|---|
| **Virtualization** | VirtualBox 7.x |
| **Operating Systems** | Ubuntu Server 22.04, Kali Linux |
| **Honeypot** | Cowrie 2.5+ (SSH/Telnet) |
| **SIEM** | Elasticsearch, Logstash, Kibana (ELK 8.x) |
| **Attack Tools** | Nmap, Hydra |
| **Languages** | Bash, JSON |

---

##  Future Improvements

- [ ] Deploy additional honeypots (HTTP via Dionaea, SMB via HoneySMB)
- [ ] Add automated attack-simulation scripts with randomized timing
- [ ] Integrate threat-intelligence IP reputation feeds (AbuseIPDB, VirusTotal)
- [ ] Expand lab to include Active Directory monitoring with BloodHound
- [ ] Add Suricata IDS for network-level intrusion detection
- [ ] Implement alerting via Kibana Watcher or ElastAlert

---

## Repository Structure

```
honeypot-security-lab/
├── README.md
├── LICENSE
├── docs/
│   └── architecture-diagram.svg
├── scripts/
│   ├── setup-vms.sh
│   ├── install-cowrie.sh
│   ├── install-elk.sh
│   └── run-attack-sim.sh
└── configs/
    ├── cowrie/
    │   └── cowrie.cfg
    ├── logstash/
    │   └── cowrie-pipeline.conf
    └── kibana/
        └── dashboard-export.ndjson
```

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

##  Author

**Yousif Nazhat**
- [GitHub](https://github.com/yousifnazhat)
- [LinkedIn](https://linkedin.com/in/yousif-nazhat-526027296)
- [ePortfolio] (https://yousifsportfolio.vercel.app/) 
