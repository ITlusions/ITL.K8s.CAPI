#!/usr/bin/env bash
#
# Workflow Status Checker
# Checks the status of GitHub Actions workflows for the ITL.K8s.Capi repository
#

set -euo pipefail

# Configuration
REPO_OWNER="ITlusions"
REPO_NAME="ITL.K8s.CAPI"
GITHUB_API="https://api.github.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Workflow files to check
WORKFLOWS=(
    "test-chart.yml"
    "release-chart.yml"
    "dependency-updates.yml"
    "pr-validation.yml"
)

echo -e "${BLUE}🔍 Checking GitHub Actions workflow status for ${REPO_OWNER}/${REPO_NAME}${NC}\n"

# Function to get workflow status
get_workflow_status() {
    local workflow_file=$1
    local response
    
    response=$(curl -s -H "Accept: application/vnd.github.v3+json" \
        "${GITHUB_API}/repos/${REPO_OWNER}/${REPO_NAME}/actions/workflows/${workflow_file}/runs?per_page=1")
    
    if [[ $(echo "$response" | jq -r '.workflow_runs | length') -eq 0 ]]; then
        echo "no_runs"
        return
    fi
    
    local status=$(echo "$response" | jq -r '.workflow_runs[0].status')
    local conclusion=$(echo "$response" | jq -r '.workflow_runs[0].conclusion')
    local created_at=$(echo "$response" | jq -r '.workflow_runs[0].created_at')
    local html_url=$(echo "$response" | jq -r '.workflow_runs[0].html_url')
    
    echo "${status}|${conclusion}|${created_at}|${html_url}"
}

# Function to format status
format_status() {
    local status=$1
    local conclusion=$2
    
    if [[ "$status" == "completed" ]]; then
        case "$conclusion" in
            "success")
                echo -e "${GREEN}✅ Success${NC}"
                ;;
            "failure")
                echo -e "${RED}❌ Failed${NC}"
                ;;
            "cancelled")
                echo -e "${YELLOW}⚠️  Cancelled${NC}"
                ;;
            "skipped")
                echo -e "${YELLOW}⏭️  Skipped${NC}"
                ;;
            *)
                echo -e "${YELLOW}❓ $conclusion${NC}"
                ;;
        esac
    elif [[ "$status" == "in_progress" ]]; then
        echo -e "${BLUE}🔄 Running${NC}"
    elif [[ "$status" == "queued" ]]; then
        echo -e "${YELLOW}⏳ Queued${NC}"
    else
        echo -e "${YELLOW}❓ $status${NC}"
    fi
}

# Function to format date
format_date() {
    local iso_date=$1
    if command -v date >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso_date" "+%Y-%m-%d %H:%M:%S"
        else
            # Linux
            date -d "$iso_date" "+%Y-%m-%d %H:%M:%S"
        fi
    else
        echo "$iso_date"
    fi
}

# Check if required tools are available
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}❌ curl is required but not installed${NC}"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo -e "${RED}❌ jq is required but not installed${NC}"
    exit 1
fi

# Check each workflow
for workflow in "${WORKFLOWS[@]}"; do
    echo -e "${BLUE}📋 $workflow${NC}"
    
    result=$(get_workflow_status "$workflow")
    
    if [[ "$result" == "no_runs" ]]; then
        echo -e "   Status: ${YELLOW}⚪ No runs found${NC}"
    else
        IFS='|' read -r status conclusion created_at html_url <<< "$result"
        
        formatted_status=$(format_status "$status" "$conclusion")
        formatted_date=$(format_date "$created_at")
        
        echo -e "   Status: $formatted_status"
        echo -e "   Last Run: $formatted_date"
        echo -e "   URL: $html_url"
    fi
    echo
done

# Summary
echo -e "${BLUE}📊 Summary${NC}"
echo "Repository: https://github.com/${REPO_OWNER}/${REPO_NAME}"
echo "Actions: https://github.com/${REPO_OWNER}/${REPO_NAME}/actions"
echo

# Check for recent failures
echo -e "${BLUE}🔍 Checking for recent failures...${NC}"
recent_failures=$(curl -s -H "Accept: application/vnd.github.v3+json" \
    "${GITHUB_API}/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs?status=failure&per_page=5")

failure_count=$(echo "$recent_failures" | jq -r '.workflow_runs | length')

if [[ "$failure_count" -gt 0 ]]; then
    echo -e "${RED}⚠️  Found $failure_count recent failures:${NC}"
    echo "$recent_failures" | jq -r '.workflow_runs[] | "   - \(.name): \(.conclusion) (\(.created_at))"'
else
    echo -e "${GREEN}✅ No recent failures found${NC}"
fi

echo -e "\n${GREEN}✅ Workflow status check completed${NC}"
