# 📋 Installation Summary & Rollback Guide

## What the Installation Script Will Do

### 🔍 **Pre-Installation Checks**
- ✅ Check for `curl` (usually pre-installed)
- ✅ Check for `jq` JSON processor
  - **If missing**: Script stops with installation instructions
  - **macOS**: `brew install jq`
  - **Ubuntu/Debian**: `sudo apt-get install jq`

### 📁 **Files & Directories Created**
```bash
# Main executable (15KB bash script)
~/.local/bin/jesc

# Configuration directory
~/.config/jira-escalation-analyzer/
├── org-config.yaml          # Organization template (1KB)
└── config                   # Created later during setup
└── analysis_*/              # Created during usage

# Shell configuration modification
~/.zshrc or ~/.bashrc        # PATH entry added
```

### 🛠️ **System Changes**
1. **PATH Modification**: Adds `~/.local/bin` to your PATH in shell config
2. **No Root Access**: Everything installs in your home directory
3. **No System Dependencies**: Only uses existing system tools + jq
4. **No Network Access After Install**: Tool only makes API calls to your Jira instance

### 📊 **Disk Usage**
- **Initial**: ~16KB (executable + config template)
- **After Setup**: ~16KB + credentials (minimal)
- **During Usage**: ~1-5MB per analysis (JSON data saved locally)

## 🚀 Safe Installation Process

The script uses `set -e` which means:
- **Stops immediately** if any command fails
- **No partial installations** that leave your system in a broken state
- **Rollback-friendly** design

## 🔄 Complete Rollback Options

### **Option 1: Automated Uninstall (Recommended)**
```bash
./uninstall.sh
```
**What it does:**
- ✅ Removes main executable
- ✅ Removes configuration directory (with confirmation)
- ✅ Removes PATH modification from shell config
- ✅ Finds and optionally removes analysis directories
- ✅ Creates backups before making changes
- ✅ Interactive confirmations for each step

### **Option 2: Manual Rollback**
If you prefer to do it manually or the uninstall script isn't available:

#### **Step 1: Remove Executable**
```bash
rm -f ~/.local/bin/jesc
```

#### **Step 2: Remove Configuration**
```bash
rm -rf ~/.config/jira-escalation-analyzer
```

#### **Step 3: Remove PATH Entry**
Edit your shell config file:
```bash
# For zsh users
nano ~/.zshrc

# For bash users  
nano ~/.bashrc

# Remove this line:
export PATH="$HOME/.local/bin:$PATH"
```

#### **Step 4: Remove Analysis Data (Optional)**
```bash
find ~/.config -name "analysis_*" -type d -exec rm -rf {} \;
```

#### **Step 5: Restart Terminal**
```bash
source ~/.zshrc  # or ~/.bashrc
```

### **Option 3: Partial Rollback**
You can selectively remove components:

#### **Keep Tool, Remove Data**
```bash
rm -rf ~/.config/jira-escalation-analyzer/analysis_*
```

#### **Keep Tool, Reset Configuration**
```bash
rm -f ~/.config/jira-escalation-analyzer/config
jesc --setup  # Reconfigure
```

## 🔒 Security Considerations

### **What's Safe:**
- ✅ **No root access required**
- ✅ **All files in your home directory**
- ✅ **No system-wide changes**
- ✅ **Only modifies your shell config**
- ✅ **Credentials stored locally with 600 permissions**
- ✅ **Open source - you can inspect the code**

### **What to Know:**
- 🔐 **API Token Required**: You'll need to generate a Jira API token
- 📊 **Data Storage**: Analysis results saved locally for historical reference
- 🌐 **Network Access**: Makes HTTPS calls to your Jira instance
- 📝 **Shell Config**: Adds PATH entry to make command globally available

## 🧪 Test Installation (Dry Run)

Want to see what would happen without actually installing?

```bash
# Review the install script first
cat install.sh | head -50

# Check dependencies manually
command -v curl && echo "✅ curl found" || echo "❌ curl missing"
command -v jq && echo "✅ jq found" || echo "❌ jq missing"

# See what directories would be created
echo "Would create:"
echo "  ~/.local/bin/jesc"
echo "  ~/.config/jira-escalation-analyzer/"
```

## 📈 Usage After Installation

### **Initial Setup (One-time)**
```bash
jesc --setup
```
**Prompts for:**
- Jira domain (e.g., `company.atlassian.net`)
- Your email address
- API token (from Atlassian account settings)

### **Daily Usage**
```bash
# Analyze any ticket
jesc "https://company.atlassian.net/browse/DEV-1234"
jesc "DEV-1234"

# Get help
jesc --help
```

## ⚠️ Troubleshooting

### **Installation Issues**

#### **"jq not found"**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

#### **"Permission denied"**
```bash
chmod +x install.sh
./install.sh
```

#### **"Command not found: jesc"**
```bash
# Restart terminal or reload shell config
source ~/.zshrc  # or ~/.bashrc

# Or temporarily add to PATH
export PATH="$HOME/.local/bin:$PATH"
```

### **Usage Issues**

#### **"Configuration not found"**
```bash
jesc --setup
```

#### **"Failed to fetch issue data"**
- Check your API token at: https://id.atlassian.com/manage-profile/security/api-tokens
- Verify you have access to the Jira project
- Ensure ticket key format is correct (e.g., `PROJ-123`)

## 🎯 Decision Framework

### **Install if:**
- ✅ You handle Jira escalations regularly
- ✅ You want faster incident response
- ✅ You're comfortable with CLI tools
- ✅ You have Jira Cloud access

### **Consider alternatives if:**
- ❌ You rarely handle escalations
- ❌ You prefer web-only interfaces
- ❌ You don't have Jira API access
- ❌ Your organization restricts CLI tools

## 📞 Support

### **Installation Support**
- **Slack**: `#jescr` (after tool rollout)
- **Documentation**: `README.md`
- **Issues**: Manual troubleshooting in this guide

### **Rollback Support**
- **Automated**: Use `./uninstall.sh`
- **Manual**: Follow steps in this guide
- **Emergency**: Simply delete `~/.local/bin/jesc` to disable

---

## 🚀 Ready to Install?

The installation is **safe**, **reversible**, and **user-friendly**. 

**Quick Start:**
```bash
# 1. Install
./install.sh

# 2. Setup (after installation)
jesc --setup

# 3. Test
jesc "PROJ-123"

# 4. Rollback anytime
./uninstall.sh
```

**Questions?** Everything is documented and reversible. You can always uninstall completely if it doesn't meet your needs. 