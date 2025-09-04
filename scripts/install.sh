#!/bin/bash

# Jira Ticket Context - Streamlined Installation
# Creates the 'jesc' command for fast ticket context extraction

set -e

TOOL_NAME="jira-ticket-context"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/$TOOL_NAME"
TOOL_VERSION="1.1.0"

echo "🚀 Installing Jira Ticket Context v$TOOL_VERSION"
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

# Jira Ticket Context - Fast Context Tool
# Usage: jesc <jira-url> [options]

TOOL_DIR="$HOME/.config/jira-ticket-context"
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
🎯 Jira Ticket Context v$VERSION

USAGE:
  jesc <jira-url>                    # Extract ticket context (30-second)
  jesc --setup                       # Initial configuration
  jesc --config                      # Update configuration
  jesc --cleanup                     # Remove context data  
  jesc --help                        # Show this help
  jesc --version                     # Show version

EXAMPLES:
  jesc "https://company.atlassian.net/browse/DEV-1234"
  jesc "DEV-1234"                    # If default domain configured
  jesc --setup                       # First-time setup

FEATURES:
  ⚡ 30-second context extraction (vs 30-minute manual research)
  📊 Complete context: comments, links, history, similar tickets
  🤖 Perfect for AI tools (Cursor, ChatGPT, Claude)
  💾 Memory optimized (no directory accumulation)
  🔄 Always fresh data from Jira API

Get rich ticket context for any workflow!
EOF
}

show_version() {
    echo "Jira Ticket Context v$VERSION"
}

cleanup_data() {
    echo -e "${BLUE}🧹 Cleaning up context data...${NC}"
    
    CONTEXT_DIRS=$(find "$TOOL_DIR" -name "current_context_*" -type d 2>/dev/null || true)
    OLD_DIRS=$(find "$TOOL_DIR" -name "context_*" -type d 2>/dev/null || true)
    
    TOTAL_DIRS=$(echo "$CONTEXT_DIRS $OLD_DIRS" | wc -w | tr -d ' ')
    
    if [[ "$TOTAL_DIRS" -eq 0 ]]; then
        echo "✅ No context data found to clean up"
        return
    fi
    
    echo "Found $TOTAL_DIRS context directories:"
    echo "$CONTEXT_DIRS $OLD_DIRS" | tr ' ' '\n' | grep -v '^$' | while read -r dir; do
        echo "  $dir"
    done
    
    echo ""
    echo -n "Remove all context data? (y/N): "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf $CONTEXT_DIRS $OLD_DIRS 2>/dev/null || true
        echo "✅ All context data removed"
        echo -e "${GREEN}💾 Disk space freed up!${NC}"
    else
        echo "⏭️  Cleanup cancelled"
    fi
}

setup_config() {
    echo -e "${BLUE}🛠️  Jira Ticket Context Setup${NC}"
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
    echo "3. Label it 'Ticket Context'"
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
# Jira Ticket Context Configuration
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

extract_context() {
    local jira_input="$1"
    
    extract_ticket_info "$jira_input"
    load_config
    
    echo -e "${PURPLE}📊 TICKET CONTEXT EXTRACTION${NC}"
    echo "=================================="
    echo -e "${CYAN}🔗 Extracting context for:${NC} $jira_input"
    echo -e "${CYAN}🎫 Ticket:${NC} $TICKET_KEY"
    echo -e "${CYAN}📁 Project:${NC} $PROJECT_KEY"
    echo -e "${CYAN}🌐 Domain:${NC} $JIRA_DOMAIN"
    echo ""
    
    # Create context directory (reuse same name to avoid accumulation)
    CONTEXT_DIR="$TOOL_DIR/current_context_$TICKET_KEY"
    rm -rf "$CONTEXT_DIR" 2>/dev/null  # Remove previous context for this ticket
    mkdir -p "$CONTEXT_DIR"
    cd "$CONTEXT_DIR"
    
    AUTH="$JIRA_EMAIL:$JIRA_TOKEN"
    BASE_URL="https://$JIRA_DOMAIN/rest/api/3"
    
    echo -e "${BLUE}⬇️  FETCHING COMPREHENSIVE DATA...${NC}"
    
    # Primary Issue Data
    echo "📋 Getting issue details..."
    if ! curl -s -u "$AUTH" \
      "$BASE_URL/issue/$TICKET_KEY?expand=names,renderedFields,comments,attachments,changelog,transitions,issuelinks,subtasks,worklog,versions,operations" \
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
    
    # Recent Project Activity & Project Metadata
    echo "📊 Getting recent project activity..."
    curl -s -u "$AUTH" \
      "$BASE_URL/search?jql=project=$PROJECT_KEY AND updated>=-7d ORDER BY updated DESC&maxResults=15" \
      -o recent_activity.json
    
    echo "📁 Getting project metadata..."
    curl -s -u "$AUTH" \
      "$BASE_URL/project/$PROJECT_KEY" \
      -o project_metadata.json
    
    # Enhanced Similar Issues Search
    SUMMARY=$(jq -r '.fields.summary' issue_data.json 2>/dev/null)
    KEYWORDS=$(echo "$SUMMARY" | grep -oE '\b[A-Za-z]{4,}\b' | head -3 | tr '\n' ' ')
    COMPONENTS=$(jq -r '.fields.components[]?.name // empty' issue_data.json 2>/dev/null | head -2 | tr '\n' ',' | sed 's/,$//')
    LABELS=$(jq -r '.fields.labels[]? // empty' issue_data.json 2>/dev/null | head -2 | tr '\n' ',' | sed 's/,$//')
    ASSIGNEE=$(jq -r '.fields.assignee?.name // empty' issue_data.json 2>/dev/null)
    
    echo "🔍 Searching similar issues with keywords: $KEYWORDS"
    
    # Multi-dimensional similarity search
    SIMILARITY_JQL="project=$PROJECT_KEY AND ("
    [[ -n "$KEYWORDS" ]] && SIMILARITY_JQL+="text~\"$KEYWORDS\" OR "
    [[ -n "$COMPONENTS" ]] && SIMILARITY_JQL+="component in ($COMPONENTS) OR "
    [[ -n "$LABELS" ]] && SIMILARITY_JQL+="labels in ($LABELS) OR "
    [[ -n "$ASSIGNEE" ]] && SIMILARITY_JQL+="assignee=\"$ASSIGNEE\" OR "
    SIMILARITY_JQL="${SIMILARITY_JQL% OR *}) AND key!=$TICKET_KEY ORDER BY updated DESC"
    
    curl -s -u "$AUTH" \
      "$BASE_URL/search?jql=$SIMILARITY_JQL&maxResults=12" \
      -o similar_issues.json
    
    # Assignee workload context
    if [[ -n "$ASSIGNEE" ]]; then
        echo "👤 Getting assignee workload..."
        curl -s -u "$AUTH" \
          "$BASE_URL/search?jql=assignee=\"$ASSIGNEE\" AND resolution=Unresolved ORDER BY priority DESC&maxResults=8" \
          -o assignee_workload.json
    fi
    
    echo ""
    echo -e "${GREEN}🧠 CONTEXT EXTRACTION COMPLETE${NC}"
    echo "==============================="
    
    # Run the context display
    display_context
    
    echo ""
    echo -e "${BLUE}📁 Context files saved in:${NC}"
    echo "  $CONTEXT_DIR"
    echo ""
    echo -e "${GREEN}✅ Context ready! Perfect for AI tools or team collaboration!${NC}"
    echo -e "${CYAN}💡 Note: Previous context for this ticket was replaced to save disk space${NC}"
}

display_context() {
    # Enhanced Issue Overview
    echo ""
    jq -r '
    "📋 ISSUE OVERVIEW:",
    "  Key: " + .key,
    "  Summary: " + .fields.summary,
    "  Status: " + .fields.status.name + " (" + (.fields.status.statusCategory.name // "Unknown") + ")",
    "  Priority: " + .fields.priority.name,
    "  Type: " + .fields.issuetype.name,
    "  Assignee: " + (.fields.assignee.displayName // "Unassigned"),
    "  Reporter: " + .fields.reporter.displayName,
    "  Created: " + (.fields.created | split("T")[0]),
    "  Updated: " + (.fields.updated | split("T")[0]),
    "  Resolution: " + (.fields.resolution.name // "Unresolved"),
    if .fields.environment then "  Environment: " + (.fields.environment | tostring | .[0:100]) else empty end,
    ""
    ' issue_data.json
    
    # Time Tracking & Effort Details
    jq -r '
    if (.fields.timeoriginalestimate or .fields.timeestimate or .fields.timespent or .fields.aggregatetimespent) then
    "⏱️  TIME TRACKING:",
    (if .fields.timeoriginalestimate then "  Original Estimate: " + (.fields.timeoriginalestimate / 3600 | floor | tostring) + "h" else empty end),
    (if .fields.timeestimate then "  Remaining: " + (.fields.timeestimate / 3600 | floor | tostring) + "h" else empty end),
    (if .fields.timespent then "  Time Spent: " + (.fields.timespent / 3600 | floor | tostring) + "h" else empty end),
    (if .fields.aggregatetimespent then "  Total Spent (inc. subtasks): " + (.fields.aggregatetimespent / 3600 | floor | tostring) + "h" else empty end),
    ""
    else empty end
    ' issue_data.json
    
    # Enhanced Categorization
    jq -r '
    "🏷️  CATEGORIZATION:",
    "  Components: " + (if .fields.components | length > 0 then (.fields.components | map(.name) | join(", ")) else "None" end),
    "  Labels: " + (if .fields.labels | length > 0 then (.fields.labels | join(", ")) else "None" end),
    "  Fix Version: " + (if .fields.fixVersions | length > 0 then (.fields.fixVersions | map(.name) | join(", ")) else "None" end),
    "  Affected Versions: " + (if .fields.versions | length > 0 then (.fields.versions | map(.name) | join(", ")) else "None" end),
    "  Security Level: " + (.fields.security.name // "None"),
    ""
    ' issue_data.json
    
    # Project Context
    if [[ -f "project_metadata.json" ]]; then
        echo "📁 PROJECT CONTEXT:"
        jq -r '
        "  Project: " + .name + " (" + .key + ")",
        "  Lead: " + (.lead.displayName // "Unknown"),
        "  Type: " + (.projectTypeKey // "Unknown"),
        "  Category: " + (.projectCategory.name // "Uncategorized"),
        ""
        ' project_metadata.json 2>/dev/null || echo "  Project metadata unavailable"
        echo ""
    fi
    
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
    
    # Enhanced Similar Tickets Search
    echo "🔄 SIMILAR TICKETS FOUND:"
    SIMILAR_COUNT=$(jq '.issues | length' similar_issues.json 2>/dev/null || echo "0")
    if [[ "$SIMILAR_COUNT" -gt 0 ]]; then
        echo "  Found $SIMILAR_COUNT related issues:"
        jq -r '.issues[] | 
        "  " + .key + " [" + .fields.status.name + "] " + .fields.summary + 
        (if .fields.resolution then " (Resolved: " + .fields.resolution.name + ")" else "" end)' similar_issues.json
        echo ""
        
        # Pattern Details
        echo "🔍 PATTERN INSIGHTS:"
        RESOLVED_COUNT=$(jq '[.issues[] | select(.fields.resolution != null)] | length' similar_issues.json 2>/dev/null || echo "0")
        OPEN_COUNT=$((SIMILAR_COUNT - RESOLVED_COUNT))
        echo "  Resolution Rate: $RESOLVED_COUNT/$SIMILAR_COUNT resolved ($((RESOLVED_COUNT * 100 / SIMILAR_COUNT))%)"
        echo "  Active Similar Issues: $OPEN_COUNT"
        
        # Most common components in similar issues
        COMMON_COMPONENTS=$(jq -r '[.issues[].fields.components[]?.name] | group_by(.) | map({component: .[0], count: length}) | sort_by(.count) | reverse | .[0:3][] | "    " + .component + " (" + (.count | tostring) + "x)"' similar_issues.json 2>/dev/null)
        if [[ -n "$COMMON_COMPONENTS" ]]; then
            echo "  Common Components:"
            echo "$COMMON_COMPONENTS"
        fi
    else
        echo "  No similar issues found"
    fi
    echo ""
    
    # Assignee Workload Context
    if [[ -f "assignee_workload.json" ]]; then
        WORKLOAD_COUNT=$(jq '.issues | length' assignee_workload.json 2>/dev/null || echo "0")
        if [[ "$WORKLOAD_COUNT" -gt 0 ]]; then
            echo "👤 ASSIGNEE WORKLOAD:"
            ASSIGNEE_NAME=$(jq -r '.issues[0].fields.assignee.displayName' assignee_workload.json 2>/dev/null)
            echo "  $ASSIGNEE_NAME has $WORKLOAD_COUNT unresolved issues:"
            jq -r '.issues[0:5][] | "    " + .key + " [" + .fields.priority.name + "] " + (.fields.summary | .[0:60])' assignee_workload.json 2>/dev/null
            [[ "$WORKLOAD_COUNT" -gt 5 ]] && echo "    ... and $((WORKLOAD_COUNT - 5)) more issues"
            echo ""
        fi
    fi
    
    # Comprehensive Executive Summary
    echo -e "${YELLOW}🎯 TICKET CONTEXT SUMMARY:${NC}"
    echo "============================================="
    
    STATUS=$(jq -r '.fields.status.name' issue_data.json)
    PRIORITY=$(jq -r '.fields.priority.name' issue_data.json)
    ISSUE_TYPE=$(jq -r '.fields.issuetype.name' issue_data.json)
    ASSIGNEE=$(jq -r '.fields.assignee.displayName // "Unassigned"' issue_data.json)
    COMMENT_COUNT=$(jq '.fields.comment.comments | length' issue_data.json)
    LINKED_COUNT=$(jq '.fields.issuelinks | length' issue_data.json)
    WORKLOG_COUNT=$(jq '.fields.worklog.total // 0' issue_data.json)
    TIME_SPENT=$(jq -r 'if .fields.timespent then (.fields.timespent / 3600 | floor | tostring) + "h" else "Not tracked" end' issue_data.json)
    
    echo "📊 CURRENT STATE:"
    echo "• Status: $STATUS | Priority: $PRIORITY | Type: $ISSUE_TYPE"
    echo "• Assigned to: $ASSIGNEE"
    echo "• Effort: $TIME_SPENT invested ($WORKLOG_COUNT work log entries)"
    echo "• Activity: $COMMENT_COUNT comments, $LINKED_COUNT linked issues"
    echo "• Similar issues: $SIMILAR_COUNT found, $RESOLVED_COUNT resolved"
    
    # Business Impact Assessment
    echo ""
    echo "💼 BUSINESS IMPACT ASSESSMENT:"
    if jq -e '.fields.priority.name == "Critical" or .fields.priority.name == "High"' issue_data.json > /dev/null; then
        echo "• ⚠️  HIGH PRIORITY - Requires immediate attention"
    fi
    
    if jq -e '.fields.labels[]? | test("production|prod|outage|revenue")' issue_data.json > /dev/null; then
        echo "• 🚨 PRODUCTION IMPACT - Customer-facing issue detected"
    fi
    
    if [[ "$OPEN_COUNT" -gt 2 ]]; then
        echo "• 🔄 PATTERN CONCERN - $OPEN_COUNT similar unresolved issues (potential systemic problem)"
    fi
    
    if [[ "$WORKLOAD_COUNT" -gt 8 ]]; then
        echo "• 👤 RESOURCE CONCERN - Assignee has $WORKLOAD_COUNT unresolved issues"
    fi
    
    # AI Context Optimization Score
    CONTEXT_SCORE=0
    [[ "$COMMENT_COUNT" -gt 0 ]] && ((CONTEXT_SCORE += 15))
    [[ "$LINKED_COUNT" -gt 0 ]] && ((CONTEXT_SCORE += 15))
    [[ "$SIMILAR_COUNT" -gt 0 ]] && ((CONTEXT_SCORE += 20))
    [[ "$WORKLOG_COUNT" -gt 0 ]] && ((CONTEXT_SCORE += 20))
    [[ -f "project_metadata.json" ]] && ((CONTEXT_SCORE += 15))
    [[ -f "assignee_workload.json" ]] && ((CONTEXT_SCORE += 15))
    
    echo ""
    echo "🤖 AI CONTEXT COMPLETENESS: $CONTEXT_SCORE/100"
    [[ "$CONTEXT_SCORE" -ge 80 ]] && echo "✅ Excellent context for AI analysis"
    [[ "$CONTEXT_SCORE" -ge 60 && "$CONTEXT_SCORE" -lt 80 ]] && echo "⚠️  Good context, some details missing"
    [[ "$CONTEXT_SCORE" -lt 60 ]] && echo "❌ Limited context available"
    
    echo ""
    echo "📅 Context extracted: $(date)"
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
        extract_context "$1"
        ;;
esac
TOOL_EOF

# Make executable
chmod +x "$INSTALL_DIR/jesc"

# Add to PATH if not already there
# Determine shell config file
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    SHELL_CONFIG="$HOME/.bashrc"
fi

# Check if PATH export exists in shell config (not just current PATH)
if ! grep -q "\.local/bin" "$SHELL_CONFIG" 2>/dev/null; then
    echo ""
    echo "📝 Adding to PATH in $SHELL_CONFIG..."
    
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_CONFIG"
    export PATH="$HOME/.local/bin:$PATH"
    
    echo "✅ Added $INSTALL_DIR to PATH in $SHELL_CONFIG"
    echo "🔄 Loading updated PATH in current session..."
    source "$SHELL_CONFIG" 2>/dev/null || true
else
    echo "✅ PATH already configured in $SHELL_CONFIG"
    # Still export for current session in case it's not in current PATH
    export PATH="$HOME/.local/bin:$PATH"
fi

echo ""
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo "========================"
echo ""
echo "✨ WHAT'S NEW:"
echo "• Short command: jesc (get any ticket context)"
echo "• Works with Stories, Bugs, Tasks, Epics"
echo "• 30-second context extraction"
echo "• Perfect for AI tools (Cursor, ChatGPT, etc)"
echo ""
echo "Next steps:"
echo "1. Restart terminal or: source $SHELL_CONFIG"
echo "2. Setup: jesc --setup"
echo "3. Try: jesc 'STORY-123' or jesc 'BUG-456'"
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