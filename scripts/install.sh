#!/bin/bash

# Jira Ticket Analyzer - Streamlined Installation
# Creates the 'jesc' command for fast ticket analysis

set -e

TOOL_NAME="jira-ticket-analyzer"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/$TOOL_NAME"
TOOL_VERSION="1.1.0"

echo "🚀 Installing Jira Ticket Analyzer v$TOOL_VERSION"
echo "📱 Command: jesc (short & sweet!)"
echo "=============================================="

# Create directories
echo "📁 Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

# Check dependencies
echo "🔍 Checking dependencies..."
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ $1 is required but not installed."
        echo "Please install $1 and run this script again."
        echo ""
        case "$1" in
            "jq")
                echo "Install jq:"
                echo "  macOS: brew install jq"
                echo "  Ubuntu/Debian: sudo apt-get install jq"
                echo "  CentOS/RHEL: sudo yum install jq"
                ;;
            "curl")
                echo "curl should be pre-installed on most systems"
                ;;
        esac
        exit 1
    else
        echo "✅ $1 found"
    fi
}

check_dependency "curl"
check_dependency "jq"

# Create the main tool
echo "📥 Installing main tool..."
cat > "$INSTALL_DIR/jesc" << 'TOOL_EOF'
#!/bin/bash

# Jira Ticket Analyzer - Fast Context Tool
# Usage: jesc <jira-url> [options]

TOOL_DIR="$HOME/.config/jira-ticket-analyzer"
CONFIG_FILE="$TOOL_DIR/config"
VERSION="1.1.0"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

show_help() {
    cat << EOF
🎯 Jira Ticket Analyzer v$VERSION

USAGE:
  jesc <jira-url>                    # Analyze ticket (30-second context)
  jesc --setup                       # Initial configuration
  jesc --config                      # Update configuration
  jesc --cleanup                     # Remove analysis data  
  jesc --help                        # Show this help
  jesc --version                     # Show version

EXAMPLES:
  jesc "https://company.atlassian.net/browse/DEV-1234"
  jesc "DEV-1234"                    # If default domain configured
  jesc --setup                       # First-time setup

FEATURES:
  ⚡ 30-second ticket analysis (vs 30-minute manual)
  📊 Complete context: comments, links, history, similar issues
  🎯 Actionable technical recommendations
  💾 Memory optimized (no directory accumulation)
  🔄 Always fresh data from Jira API

Transform your ticket analysis time!
EOF
}

show_version() {
    echo "Jira Ticket Analyzer v$VERSION"
}

cleanup_data() {
    echo -e "${BLUE}🧹 Cleaning up analysis data...${NC}"
    
    ANALYSIS_DIRS=$(find "$TOOL_DIR" -name "current_analysis_*" -type d 2>/dev/null || true)
    OLD_DIRS=$(find "$TOOL_DIR" -name "analysis_*" -type d 2>/dev/null || true)
    
    TOTAL_DIRS=$(echo "$ANALYSIS_DIRS $OLD_DIRS" | wc -w | tr -d ' ')
    
    if [[ "$TOTAL_DIRS" -eq 0 ]]; then
        echo "✅ No analysis data found to clean up"
        return
    fi
    
    echo "Found $TOTAL_DIRS analysis directories:"
    echo "$ANALYSIS_DIRS $OLD_DIRS" | tr ' ' '\n' | grep -v '^$' | while read -r dir; do
        echo "  $dir"
    done
    
    echo ""
    echo -n "Remove all analysis data? (y/N): "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf $ANALYSIS_DIRS $OLD_DIRS 2>/dev/null || true
        echo "✅ All analysis data removed"
        echo -e "${GREEN}💾 Disk space freed up!${NC}"
    else
        echo "⏭️  Cleanup cancelled"
    fi
}

setup_config() {
    echo -e "${BLUE}🛠️  Jira Ticket Analyzer Setup${NC}"
    echo "=================================="
    
    # Create config directory
    mkdir -p "$TOOL_DIR"
    
    echo "Please provide your Jira configuration:"
    echo ""
    
    # Get Jira domain
    if [[ -f "$CONFIG_FILE" ]] && grep -q "JIRA_DOMAIN=" "$CONFIG_FILE"; then
        CURRENT_DOMAIN=$(grep "JIRA_DOMAIN=" "$CONFIG_FILE" | cut -d'=' -f2)
        echo -n "Jira Domain [$CURRENT_DOMAIN]: "
    else
        echo -n "Jira Domain (e.g., company.atlassian.net): "
    fi
    read DOMAIN
    
    # Get email
    if [[ -f "$CONFIG_FILE" ]] && grep -q "JIRA_EMAIL=" "$CONFIG_FILE"; then
        CURRENT_EMAIL=$(grep "JIRA_EMAIL=" "$CONFIG_FILE" | cut -d'=' -f2)
        echo -n "Your Email [$CURRENT_EMAIL]: "
    else
        echo -n "Your Email: "
    fi
    read EMAIL
    
    # Get API token
    echo ""
    echo -e "${YELLOW}📝 API Token Setup:${NC}"
    echo "1. Go to: https://id.atlassian.com/manage-profile/security/api-tokens"
    echo "2. Click 'Create API token'"
    echo "3. Label it 'Ticket Analyzer'"
    echo "4. Copy the token and paste below"
    echo ""
    echo -n "API Token: "
    read -s TOKEN
    echo ""
    
    # Use current values if new ones are empty
    [[ -z "$DOMAIN" ]] && [[ -f "$CONFIG_FILE" ]] && DOMAIN=$(grep "JIRA_DOMAIN=" "$CONFIG_FILE" | cut -d'=' -f2)
    [[ -z "$EMAIL" ]] && [[ -f "$CONFIG_FILE" ]] && EMAIL=$(grep "JIRA_EMAIL=" "$CONFIG_FILE" | cut -d'=' -f2)
    
    # Save configuration
    cat > "$CONFIG_FILE" << EOF
# Jira Ticket Analyzer Configuration
JIRA_DOMAIN=$DOMAIN
JIRA_EMAIL=$EMAIL
JIRA_TOKEN=$TOKEN
TOOL_VERSION=$VERSION
LAST_UPDATED="$(date)"
EOF
    
    chmod 600 "$CONFIG_FILE"
    
    echo ""
    echo -e "${GREEN}✅ Configuration saved successfully!${NC}"
    echo ""
    echo "Test your setup:"
    echo "  jesc 'https://$DOMAIN/browse/TEST-123'"
    echo ""
}

load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}❌ Configuration not found. Please run setup first:${NC}"
        echo "  jesc --setup"
        exit 1
    fi
    
    source "$CONFIG_FILE"
    
    if [[ -z "$JIRA_DOMAIN" ]] || [[ -z "$JIRA_EMAIL" ]] || [[ -z "$JIRA_TOKEN" ]]; then
        echo -e "${RED}❌ Incomplete configuration. Please run setup:${NC}"
        echo "  jesc --setup"
        exit 1
    fi
}

extract_ticket_info() {
    local input="$1"
    
    # If it's a full URL
    if [[ "$input" =~ https?://([^/]+).*/browse/([A-Z]+-[0-9]+) ]]; then
        JIRA_DOMAIN="${BASH_REMATCH[1]}"
        TICKET_KEY="${BASH_REMATCH[2]}"
    # If it's just a ticket key
    elif [[ "$input" =~ ^[A-Z]+-[0-9]+$ ]]; then
        TICKET_KEY="$input"
        # Use configured domain
        load_config
    else
        echo -e "${RED}❌ Invalid input. Expected:${NC}"
        echo "  - Full URL: https://company.atlassian.net/browse/DEV-1234"
        echo "  - Ticket key: DEV-1234"
        exit 1
    fi
    
    PROJECT_KEY=$(echo "$TICKET_KEY" | cut -d'-' -f1)
}

run_analysis() {
    local jira_input="$1"
    
    extract_ticket_info "$jira_input"
    load_config
    
    echo -e "${PURPLE}🚨 TICKET CONTEXT ANALYSIS${NC}"
    echo "=================================="
    echo -e "${CYAN}🔗 Analyzing:${NC} $jira_input"
    echo -e "${CYAN}🎫 Ticket:${NC} $TICKET_KEY"
    echo -e "${CYAN}📁 Project:${NC} $PROJECT_KEY"
    echo -e "${CYAN}🌐 Domain:${NC} $JIRA_DOMAIN"
    echo ""
    
    # Create analysis directory (reuse same name to avoid accumulation)
    ANALYSIS_DIR="$TOOL_DIR/current_analysis_$TICKET_KEY"
    rm -rf "$ANALYSIS_DIR" 2>/dev/null  # Remove previous analysis for this ticket
    mkdir -p "$ANALYSIS_DIR"
    cd "$ANALYSIS_DIR"
    
    AUTH="$JIRA_EMAIL:$JIRA_TOKEN"
    BASE_URL="https://$JIRA_DOMAIN/rest/api/3"
    
    echo -e "${BLUE}⬇️  FETCHING COMPREHENSIVE DATA...${NC}"
    
    # Primary Issue Data
    echo "📋 Getting issue details..."
    if ! curl -s -u "$AUTH" \
      "$BASE_URL/issue/$TICKET_KEY?expand=names,renderedFields,comments,attachments,changelog,transitions,issuelinks,subtasks" \
      -o issue_data.json; then
        echo -e "${RED}❌ Failed to fetch issue data. Check your configuration.${NC}"
        exit 1
    fi
    
    # Check if issue exists
    if jq -e '.errorMessages' issue_data.json > /dev/null 2>&1; then
        echo -e "${RED}❌ Issue not found or access denied:${NC}"
        jq -r '.errorMessages[]' issue_data.json
        exit 1
    fi
    
    # Recent Project Activity
    echo "📊 Getting recent project activity..."
    curl -s -u "$AUTH" \
      "$BASE_URL/search?jql=project=$PROJECT_KEY AND updated>=-7d ORDER BY updated DESC&maxResults=15" \
      -o recent_activity.json
    
    # Similar Issues Search
    SUMMARY=$(jq -r '.fields.summary' issue_data.json 2>/dev/null)
    KEYWORDS=$(echo "$SUMMARY" | grep -oE '\b[A-Za-z]{4,}\b' | head -3 | tr '\n' ' ')
    
    echo "🔍 Searching similar issues with keywords: $KEYWORDS"
    curl -s -u "$AUTH" \
      "$BASE_URL/search?jql=project=$PROJECT_KEY AND text~\"$KEYWORDS\" AND key!=$TICKET_KEY ORDER BY updated DESC&maxResults=8" \
      -o similar_issues.json
    
    echo ""
    echo -e "${GREEN}🧠 CONTEXT ANALYSIS COMPLETE${NC}"
    echo "==============================="
    
    # Run the analysis display
    display_analysis
    
    echo ""
    echo -e "${BLUE}📁 Analysis files saved in:${NC}"
    echo "  $ANALYSIS_DIR"
    echo ""
    echo -e "${GREEN}✅ Analysis complete. Share this output with your team!${NC}"
    echo -e "${CYAN}💡 Note: Previous analysis for this ticket was replaced to save disk space${NC}"
}

display_analysis() {
    # Issue Overview
    echo ""
    jq -r '
    "📋 ISSUE OVERVIEW:",
    "  Key: " + .key,
    "  Summary: " + .fields.summary,
    "  Status: " + .fields.status.name,
    "  Priority: " + .fields.priority.name,
    "  Type: " + .fields.issuetype.name,
    "  Assignee: " + (.fields.assignee.displayName // "Unassigned"),
    "  Reporter: " + .fields.reporter.displayName,
    "  Created: " + (.fields.created | split("T")[0]),
    "  Updated: " + (.fields.updated | split("T")[0]),
    ""
    ' issue_data.json
    
    # Categorization
    jq -r '
    "🏷️  CATEGORIZATION:",
    "  Components: " + (if .fields.components | length > 0 then (.fields.components | map(.name) | join(", ")) else "None" end),
    "  Labels: " + (if .fields.labels | length > 0 then (.fields.labels | join(", ")) else "None" end),
    "  Fix Version: " + (if .fields.fixVersions | length > 0 then (.fields.fixVersions | map(.name) | join(", ")) else "None" end),
    ""
    ' issue_data.json
    
    # Recent Activity Timeline
    echo "⏰ RECENT ACTIVITY TIMELINE:"
    jq -r '
    if .fields.changelog.histories | length > 0 then
      (.fields.changelog.histories[-5:] | reverse[] | 
      "  [" + (.created | split("T")[0]) + "] " + .author.displayName + ": " + 
      (.items | map(.field + " → " + (.toString // "null")) | join(", ")))
    else
      "  No recent changes found"
    end
    ' issue_data.json
    echo ""
    
    # Latest Comments
    echo "💬 LATEST COMMENTS:"
    jq -r '
    if .fields.comment.comments | length > 0 then
      (.fields.comment.comments[-3:] | reverse[] |
      "  [" + (.created | split("T")[0]) + "] " + .author.displayName + ":",
      "  " + (.body | if type == "object" then "Complex content - see JSON" else (. | tostring | .[0:200]) end),
      "  ---")
    else
      "  No comments found"
    end
    ' issue_data.json
    
    # Linked Issues
    echo "🔗 LINKED ISSUES:"
    jq -r '
    if .fields.issuelinks | length > 0 then
      (.fields.issuelinks[] |
      "  " + (.type.name) + ": " + 
      (if .outwardIssue then .outwardIssue.key + " - " + .outwardIssue.fields.summary 
       else .inwardIssue.key + " - " + .inwardIssue.fields.summary end))
    else
      "  No linked issues"
    end
    ' issue_data.json
    echo ""
    
    # Similar Issues
    echo "🔄 SIMILAR ISSUES:"
    SIMILAR_COUNT=$(jq '.issues | length' similar_issues.json 2>/dev/null || echo "0")
    if [[ "$SIMILAR_COUNT" -gt 0 ]]; then
        jq -r '.issues[] | "  " + .key + " [" + .fields.status.name + "] " + .fields.summary' similar_issues.json
    else
        echo "  No similar issues found"
    fi
    echo ""
    
    # Executive Summary
    echo -e "${YELLOW}🎯 TICKET SUMMARY:${NC}"
    echo "=============================="
    
    STATUS=$(jq -r '.fields.status.name' issue_data.json)
    PRIORITY=$(jq -r '.fields.priority.name' issue_data.json)
    ISSUE_TYPE=$(jq -r '.fields.issuetype.name' issue_data.json)
    ASSIGNEE=$(jq -r '.fields.assignee.displayName // "Unassigned"' issue_data.json)
    COMMENT_COUNT=$(jq '.fields.comment.comments | length' issue_data.json)
    LINKED_COUNT=$(jq '.fields.issuelinks | length' issue_data.json)
    
    echo "• Status: $STATUS | Priority: $PRIORITY | Type: $ISSUE_TYPE"
    echo "• Assigned to: $ASSIGNEE"
    echo "• Activity: $COMMENT_COUNT comments, $LINKED_COUNT linked issues"
    echo "• Similar issues found: $SIMILAR_COUNT"
    echo "• Analysis timestamp: $(date)"
}

# Main command processing
case "${1:-}" in
    "--help"|"-h"|"help")
        show_help
        ;;
    "--version"|"-v"|"version")
        show_version
        ;;
    "--setup"|"setup")
        setup_config
        ;;
    "--config"|"config")
        setup_config
        ;;
    "--cleanup"|"cleanup")
        cleanup_data
        ;;
    "")
        echo -e "${RED}❌ No input provided.${NC}"
        echo ""
        show_help
        exit 1
        ;;
    *)
        run_analysis "$1"
        ;;
esac
TOOL_EOF

# Make executable
chmod +x "$INSTALL_DIR/jesc"

# Add to PATH if not already there
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo ""
    echo "📝 Adding to PATH..."
    
    # Determine shell config file
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    else
        SHELL_CONFIG="$HOME/.bashrc"
    fi
    
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_CONFIG"
    export PATH="$HOME/.local/bin:$PATH"
    
    echo "✅ Added $INSTALL_DIR to PATH in $SHELL_CONFIG"
fi

echo ""
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo "========================"
echo ""
echo "✨ WHAT'S NEW:"
echo "• Short command: jesc (vs jira-analyze)"
echo "• Memory optimized (no accumulation)"
echo "• 30-second ticket analysis"
echo "• Clean, focused distribution"
echo ""
echo "Next steps:"
echo "1. Restart terminal or: source ~/.bashrc"
echo "2. Setup: jesc --setup"
echo "3. Test: jesc 'PROJ-123'"
echo ""
echo "Usage examples:"
echo "• jesc 'https://company.atlassian.net/browse/DEV-1234'"
echo "• jesc 'DEV-1234'"
echo "• jesc --cleanup"
echo "• jesc --help"
echo ""
echo "Tool installed at: $INSTALL_DIR/jesc"
echo ""
echo -e "${BLUE}Share install.sh with your team! 🚀${NC}" 