# 🖥️ Platform Compatibility Guide

## ✅ Supported Platforms

This WordPress Development Platform is **fully compatible** with:

### **Mac Silicon (Apple M1/M2/M3/M4)**
- ✅ **macOS Monterey (12.0+)**
- ✅ **macOS Ventura (13.0+)**
- ✅ **macOS Sonoma (14.0+)**
- ✅ **macOS Sequoia (15.0+)**

### **Intel Mac**
- ✅ **macOS Big Sur (11.0+)**
- ✅ **macOS Monterey (12.0+)**
- ✅ **macOS Ventura (13.0+)**
- ✅ **macOS Sonoma (14.0+)**

### **Linux Distributions**
- ✅ **Ubuntu 20.04 LTS+**
- ✅ **Ubuntu 22.04 LTS+**
- ✅ **Debian 11+**
- ✅ **CentOS 8+**
- ✅ **RHEL 8+**
- ✅ **Fedora 35+**
- ✅ **Arch Linux**
- ✅ **openSUSE**

### **Windows (via WSL2)**
- ✅ **Windows 11 with WSL2**
- ✅ **Windows 10 with WSL2**
- ✅ **Ubuntu on WSL2**
- ✅ **Debian on WSL2**

## 🔧 Platform-Specific Optimizations

### **Mac Silicon (ARM64) Optimizations**

The platform automatically detects and optimizes for Apple Silicon:

#### **Multi-Architecture Support**
```yaml
# Automatic platform detection in docker-compose.yml
services:
  wordpress1:
    build:
      context: ./docker/wordpress
      dockerfile: Dockerfile
      platforms:
        - linux/amd64
        - linux/arm64
```

#### **XDebug Configuration for Mac**
```bash
# Optimized for Mac Docker Desktop
XDEBUG_CLIENT_HOST=host.docker.internal
XDEBUG_CLIENT_PORT=9003
XDEBUG_IDEKEY=VSCODE
```

#### **Performance Tuning for Mac**
```bash
# Optimized resource limits for Mac Silicon
WP_MEMORY_LIMIT=1g
DB_MEMORY_LIMIT=2g
CACHE_MEMORY_LIMIT=512m
```

### **Linux Optimizations**

#### **Native Performance**
- Full native Docker performance
- Direct filesystem access
- Optimized networking
- Native cgroup support

#### **SystemD Integration**
```bash
# Optional: Run as systemd service on Linux
sudo systemctl enable docker
sudo systemctl start docker
```

#### **Resource Management**
```bash
# Linux-specific optimizations
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### **Windows WSL2 Optimizations**

#### **WSL2 Configuration**
```bash
# .wslconfig file optimization
[wsl2]
memory=8GB
processors=4
swap=2GB
```

#### **Docker Desktop Settings**
- Enable WSL2 integration
- Allocate sufficient resources
- Use WSL2 backend

## 🚀 Installation by Platform

### **Mac (Intel & Silicon)**

#### **Prerequisites**
```bash
# Install Docker Desktop for Mac
# Download from: https://www.docker.com/products/docker-desktop

# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install additional tools
brew install git curl wget
```

#### **Setup**
```bash
# Clone repository
git clone <repository-url>
cd wp-dev-platform

# Run setup
./wp-dev setup

# Start environment
./wp-dev start
```

#### **Mac-Specific Notes**
- Docker Desktop automatically handles ARM64/AMD64 translation
- File sync performance is optimized for macOS
- XDebug works out-of-the-box with popular IDEs

### **Linux**

#### **Prerequisites**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y docker.io docker-compose git curl wget

# CentOS/RHEL/Fedora
sudo dnf install -y docker docker-compose git curl wget

# Start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### **Setup**
```bash
# Clone repository
git clone <repository-url>
cd wp-dev-platform

# Set proper permissions
chmod +x wp-dev scripts/**/*.sh

# Run setup
./wp-dev setup

# Start environment
./wp-dev start
```

#### **Linux-Specific Optimizations**
```bash
# Increase vm.max_map_count for Elasticsearch
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Optimize Docker daemon
sudo mkdir -p /etc/docker
cat << EOF | sudo tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl restart docker
```

### **Windows (WSL2)**

#### **Prerequisites**
1. **Enable WSL2**
   ```powershell
   # Run in PowerShell as Administrator
   wsl --install
   wsl --set-default-version 2
   ```

2. **Install Ubuntu on WSL2**
   ```powershell
   wsl --install -d Ubuntu
   ```

3. **Install Docker Desktop**
   - Download from: https://www.docker.com/products/docker-desktop
   - Enable WSL2 integration in settings

#### **Setup in WSL2**
```bash
# Inside WSL2 Ubuntu terminal
sudo apt update
sudo apt install -y git curl wget

# Clone repository
git clone <repository-url>
cd wp-dev-platform

# Run setup
./wp-dev setup

# Start environment
./wp-dev start
```

#### **Windows-Specific Configuration**
```bash
# Create .wslconfig in Windows user directory
# C:\Users\<username>\.wslconfig
[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true
```

## 🔍 Platform Detection & Auto-Configuration

The platform automatically detects your system and applies optimizations:

### **Automatic Platform Detection**
```bash
# Platform detection in setup script
detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            if [[ $(uname -m) == "arm64" ]]; then
                PLATFORM="mac-silicon"
            else
                PLATFORM="mac-intel"
            fi
            ;;
        Linux*)
            if grep -q Microsoft /proc/version; then
                PLATFORM="wsl2"
            else
                PLATFORM="linux"
            fi
            ;;
        *)
            PLATFORM="unknown"
            ;;
    esac
}
```

### **Platform-Specific Configurations**
```bash
# Applied automatically based on platform
configure_for_platform() {
    case $PLATFORM in
        "mac-silicon")
            # ARM64 optimizations
            export DOCKER_DEFAULT_PLATFORM=linux/arm64
            ;;
        "mac-intel")
            # Intel optimizations
            export DOCKER_DEFAULT_PLATFORM=linux/amd64
            ;;
        "linux")
            # Native Linux optimizations
            configure_linux_optimizations
            ;;
        "wsl2")
            # WSL2 specific settings
            configure_wsl2_optimizations
            ;;
    esac
}
```

## 📊 Performance by Platform

### **Performance Comparison**

| Platform | Startup Time | Build Time | Runtime Performance | File Sync |
|----------|-------------|------------|-------------------|-----------|
| Mac Silicon | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Mac Intel | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Linux Native | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Windows WSL2 | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

### **Optimization Tips by Platform**

#### **Mac Silicon**
```bash
# Optimize Docker Desktop settings
# - Increase memory allocation to 8GB+
# - Enable VirtioFS for better file performance
# - Use Rosetta 2 emulation when needed

# Environment optimizations
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
```

#### **Linux**
```bash
# Use native Docker for best performance
# Enable cgroup v2 for better resource management
sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1"

# Optimize for development
echo 'fs.inotify.max_user_watches=524288' | sudo tee -a /etc/sysctl.conf
```

#### **Windows WSL2**
```bash
# Optimize WSL2 performance
# Place project files in WSL2 filesystem (/home/user/)
# Avoid Windows filesystem for better performance

# Use WSL2 Docker integration
export DOCKER_HOST=unix:///var/run/docker.sock
```

## 🛠️ Troubleshooting by Platform

### **Mac Silicon Issues**

#### **Elasticsearch ARM64 Compatibility**
```bash
# If Elasticsearch fails to start on ARM64
# The platform automatically uses AMD64 emulation
# Check logs: ./wp-dev logs elasticsearch
```

#### **XDebug Connection Issues**
```bash
# Verify Docker Desktop networking
docker run --rm -it alpine ping host.docker.internal

# Check IDE configuration
# Use host.docker.internal:9003 for connection
```

### **Linux Issues**

#### **Permission Issues**
```bash
# Fix Docker permissions
sudo usermod -aG docker $USER
newgrp docker

# Fix file permissions
sudo chown -R $USER:$USER wordpress1 wordpress2
```

#### **Elasticsearch Memory Issues**
```bash
# Increase virtual memory
sudo sysctl -w vm.max_map_count=262144
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
```

### **Windows WSL2 Issues**

#### **File Performance**
```bash
# Move project to WSL2 filesystem
mv /mnt/c/projects/wp-dev-platform ~/wp-dev-platform
cd ~/wp-dev-platform
```

#### **Memory Issues**
```powershell
# Increase WSL2 memory in .wslconfig
[wsl2]
memory=8GB
processors=4
```

## 🔄 Cross-Platform Development

### **Shared Development Workflow**
```bash
# Works identically across all platforms
./wp-dev setup          # Initial setup
./wp-dev start           # Start environment
./wp-dev shell wpcli     # Access tools
./wp-dev backup          # Create backups
./wp-dev instances create blog # Add instances
```

### **IDE Integration**
- **VS Code**: Works on all platforms with Remote-Containers
- **PhpStorm**: Full Docker integration on all platforms
- **Vim/Neovim**: Terminal-based, works everywhere
- **Sublime Text**: Cross-platform with Docker plugins

### **Team Collaboration**
```bash
# Consistent environment across team
# Same Docker images
# Same configuration files
# Same development workflow
# Platform-specific optimizations applied automatically
```

## 📋 Platform Requirements

### **Minimum System Requirements**

| Component | Mac | Linux | Windows WSL2 |
|-----------|-----|-------|--------------|
| RAM | 8GB | 8GB | 16GB |
| Storage | 20GB | 20GB | 30GB |
| CPU | 2 cores | 2 cores | 4 cores |
| Docker | 4.12+ | 20.10+ | Desktop 4.12+ |

### **Recommended System Requirements**

| Component | Mac | Linux | Windows WSL2 |
|-----------|-----|-------|--------------|
| RAM | 16GB+ | 16GB+ | 32GB+ |
| Storage | 50GB+ | 50GB+ | 100GB+ |
| CPU | 4+ cores | 4+ cores | 8+ cores |
| SSD | Yes | Yes | Yes |

## 🎯 Platform-Specific Features

### **Mac-Only Features**
- ✅ Native ARM64 performance on Apple Silicon
- ✅ Optimized file sync with VirtioFS
- ✅ Integration with macOS Keychain
- ✅ Native notification support

### **Linux-Only Features**
- ✅ Native Docker performance
- ✅ SystemD service integration
- ✅ Advanced cgroup management
- ✅ Native filesystem performance

### **WSL2-Only Features**
- ✅ Windows filesystem integration
- ✅ Visual Studio integration
- ✅ Windows Terminal support
- ✅ Hybrid development environment

## 🔧 Advanced Platform Configuration

### **Custom Platform Configurations**
```bash
# Create platform-specific overrides
# config/platform/mac-silicon.yml
# config/platform/linux.yml
# config/platform/wsl2.yml
```

### **Environment Detection**
```bash
# Automatic platform detection and configuration
# Applied during ./wp-dev setup
```

---

**The WordPress Development Platform provides a consistent, high-performance development experience across all major platforms while automatically optimizing for each platform's unique characteristics.**