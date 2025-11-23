#!/bin/bash

# API Endpoint Verification Script for GRead
# This script tests all BuddyPress v1 and GRead v1 endpoints

BASE_URL_BP="https://gread.fun/wp-json/buddypress/v1"
BASE_URL_GREAD="https://gread.fun/wp-json/gread/v1"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for success/failure
SUCCESS_COUNT=0
FAILURE_COUNT=0

# Function to test endpoint
test_endpoint() {
    local method=$1
    local url=$2
    local description=$3
    local auth_header=$4
    local data=$5

    echo -e "\n${YELLOW}Testing: ${description}${NC}"
    echo "URL: ${method} ${url}"

    if [ -n "$data" ]; then
        if [ -n "$auth_header" ]; then
            response=$(curl -s -w "\n%{http_code}" -X ${method} "${url}" \
                -H "Content-Type: application/json" \
                -H "${auth_header}" \
                -d "${data}")
        else
            response=$(curl -s -w "\n%{http_code}" -X ${method} "${url}" \
                -H "Content-Type: application/json" \
                -d "${data}")
        fi
    else
        if [ -n "$auth_header" ]; then
            response=$(curl -s -w "\n%{http_code}" -X ${method} "${url}" \
                -H "${auth_header}")
        else
            response=$(curl -s -w "\n%{http_code}" -X ${method} "${url}")
        fi
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 400 ]; then
        echo -e "${GREEN}✓ Success (HTTP ${http_code})${NC}"
        echo "Response: $(echo "$body" | head -c 200)..."
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗ Failed (HTTP ${http_code})${NC}"
        echo "Response: $body"
        ((FAILURE_COUNT++))
    fi
}

echo "========================================="
echo "  GRead API Endpoint Verification"
echo "========================================="
echo ""
echo "Note: Some endpoints require authentication."
echo "Please set JWT_TOKEN environment variable for authenticated requests."
echo ""

# Set auth header if token is provided
AUTH_HEADER=""
if [ -n "$JWT_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer ${JWT_TOKEN}"
    echo "Using JWT token for authenticated requests"
else
    echo "WARNING: JWT_TOKEN not set. Authenticated endpoints will fail."
fi

echo ""
echo "========================================="
echo "  BuddyPress v1 Endpoints"
echo "========================================="

# MEMBERS ENDPOINTS
echo -e "\n${YELLOW}=== MEMBERS ===${NC}"
test_endpoint "GET" "${BASE_URL_BP}/members?per_page=5" "Get all members (paginated)"
test_endpoint "GET" "${BASE_URL_BP}/members/1" "Get member by ID"

# ACTIVITY ENDPOINTS
echo -e "\n${YELLOW}=== ACTIVITY ===${NC}"
test_endpoint "GET" "${BASE_URL_BP}/activity?per_page=5" "Get activity feed"
test_endpoint "GET" "${BASE_URL_BP}/activity?type=activity_update&per_page=5" "Get activity updates only"

# GROUPS ENDPOINTS
echo -e "\n${YELLOW}=== GROUPS ===${NC}"
test_endpoint "GET" "${BASE_URL_BP}/groups?per_page=5" "Get all groups"
test_endpoint "GET" "${BASE_URL_BP}/groups?type=active&per_page=5" "Get active groups"

# MESSAGES ENDPOINTS (require auth)
echo -e "\n${YELLOW}=== MESSAGES ===${NC}"
if [ -n "$JWT_TOKEN" ]; then
    test_endpoint "GET" "${BASE_URL_BP}/messages?per_page=5" "Get messages" "$AUTH_HEADER"
else
    echo "Skipping messages endpoints (requires authentication)"
fi

# FRIENDS ENDPOINTS
echo -e "\n${YELLOW}=== FRIENDS ===${NC}"
test_endpoint "GET" "${BASE_URL_BP}/friends/1" "Get friends for user ID 1"

# NOTIFICATIONS ENDPOINTS (require auth)
echo -e "\n${YELLOW}=== NOTIFICATIONS ===${NC}"
if [ -n "$JWT_TOKEN" ]; then
    test_endpoint "GET" "${BASE_URL_BP}/notifications?per_page=5" "Get notifications" "$AUTH_HEADER"
else
    echo "Skipping notifications endpoints (requires authentication)"
fi

# XPROFILE ENDPOINTS
echo -e "\n${YELLOW}=== XPROFILE ===${NC}"
test_endpoint "GET" "${BASE_URL_BP}/xprofile/groups" "Get XProfile field groups"
test_endpoint "GET" "${BASE_URL_BP}/xprofile/fields?per_page=5" "Get XProfile fields"

# COMPONENTS ENDPOINTS
echo -e "\n${YELLOW}=== COMPONENTS ===${NC}"
test_endpoint "GET" "${BASE_URL_BP}/components" "Get BuddyPress components"

# SITEWIDE NOTICES ENDPOINTS
echo -e "\n${YELLOW}=== SITEWIDE NOTICES ===${NC}"
test_endpoint "GET" "${BASE_URL_BP}/sitewide-notices" "Get sitewide notices"

echo ""
echo "========================================="
echo "  GRead v1 Endpoints"
echo "========================================="

# MEMBERS ENDPOINTS (GRead)
echo -e "\n${YELLOW}=== MEMBERS (GRead) ===${NC}"
test_endpoint "GET" "${BASE_URL_GREAD}/members?per_page=5" "Get all members"
test_endpoint "GET" "${BASE_URL_GREAD}/members/1" "Get member by ID"

# USER STATS
echo -e "\n${YELLOW}=== USER STATS ===${NC}"
test_endpoint "GET" "${BASE_URL_GREAD}/user/1/stats" "Get user stats for ID 1"

# ACTIVITY (GRead)
echo -e "\n${YELLOW}=== ACTIVITY (GRead) ===${NC}"
test_endpoint "GET" "${BASE_URL_GREAD}/activity?per_page=5" "Get activity feed"

# FRIENDS (GRead)
echo -e "\n${YELLOW}=== FRIENDS (GRead) ===${NC}"
test_endpoint "GET" "${BASE_URL_GREAD}/friends/1" "Get friends for user ID 1"

# GROUPS (GRead)
echo -e "\n${YELLOW}=== GROUPS (GRead) ===${NC}"
test_endpoint "GET" "${BASE_URL_GREAD}/groups?per_page=5" "Get groups"

# ACHIEVEMENTS
echo -e "\n${YELLOW}=== ACHIEVEMENTS ===${NC}"
test_endpoint "GET" "${BASE_URL_GREAD}/achievements" "Get all achievements"
test_endpoint "GET" "${BASE_URL_GREAD}/achievements/stats" "Get achievement stats"
test_endpoint "GET" "${BASE_URL_GREAD}/achievements/leaderboard?limit=10" "Get achievements leaderboard"

# MENTIONS
echo -e "\n${YELLOW}=== MENTIONS ===${NC}"
test_endpoint "GET" "${BASE_URL_GREAD}/mentions/users?limit=10" "Get mentionable users"
test_endpoint "GET" "${BASE_URL_GREAD}/mentions/activity?limit=5" "Get mentions activity"

# BOOKS
echo -e "\n${YELLOW}=== BOOKS ===${NC}"
test_endpoint "GET" "${BASE_URL_GREAD}/books/search?query=test&per_page=5" "Search books"

# AUTHORS
echo -e "\n${YELLOW}=== AUTHORS ===${NC}"
test_endpoint "GET" "${BASE_URL_GREAD}/authors?per_page=5" "Get authors"

# MODERATION (require auth)
echo -e "\n${YELLOW}=== MODERATION ===${NC}"
if [ -n "$JWT_TOKEN" ]; then
    test_endpoint "GET" "${BASE_URL_GREAD}/user/blocked_list" "Get blocked users" "$AUTH_HEADER"
else
    echo "Skipping moderation endpoints (requires authentication)"
fi

# LIBRARY (require auth)
echo -e "\n${YELLOW}=== LIBRARY ===${NC}"
if [ -n "$JWT_TOKEN" ]; then
    test_endpoint "GET" "${BASE_URL_GREAD}/library?per_page=5" "Get user library" "$AUTH_HEADER"
else
    echo "Skipping library endpoints (requires authentication)"
fi

# USER ACHIEVEMENTS (require auth)
echo -e "\n${YELLOW}=== USER ACHIEVEMENTS ===${NC}"
if [ -n "$JWT_TOKEN" ]; then
    test_endpoint "GET" "${BASE_URL_GREAD}/me/achievements" "Get my achievements" "$AUTH_HEADER"
else
    echo "Skipping user achievements endpoints (requires authentication)"
fi

# USER MENTIONS (require auth)
echo -e "\n${YELLOW}=== USER MENTIONS ===${NC}"
if [ -n "$JWT_TOKEN" ]; then
    test_endpoint "GET" "${BASE_URL_GREAD}/me/mentions?limit=5" "Get my mentions" "$AUTH_HEADER"
else
    echo "Skipping user mentions endpoints (requires authentication)"
fi

# MESSAGES (GRead)
echo -e "\n${YELLOW}=== MESSAGES (GRead) ===${NC}"
if [ -n "$JWT_TOKEN" ]; then
    test_endpoint "GET" "${BASE_URL_GREAD}/messages?per_page=5" "Get messages" "$AUTH_HEADER"
else
    echo "Skipping messages endpoints (requires authentication)"
fi

# NOTIFICATIONS (GRead)
echo -e "\n${YELLOW}=== NOTIFICATIONS (GRead) ===${NC}"
if [ -n "$JWT_TOKEN" ]; then
    test_endpoint "GET" "${BASE_URL_GREAD}/notifications?per_page=5" "Get notifications" "$AUTH_HEADER"
else
    echo "Skipping notifications endpoints (requires authentication)"
fi

# Summary
echo ""
echo "========================================="
echo "  Verification Summary"
echo "========================================="
echo -e "${GREEN}Successful: ${SUCCESS_COUNT}${NC}"
echo -e "${RED}Failed: ${FAILURE_COUNT}${NC}"
echo "Total tested: $((SUCCESS_COUNT + FAILURE_COUNT))"

if [ "$FAILURE_COUNT" -eq 0 ]; then
    echo -e "\n${GREEN}All endpoints verified successfully!${NC}"
    exit 0
else
    echo -e "\n${YELLOW}Some endpoints failed. Check the output above for details.${NC}"
    exit 1
fi
