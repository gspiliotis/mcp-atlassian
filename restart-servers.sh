#!/bin/bash

# Kill existing servers
pkill -f "mcp-atlassian --transport streamable-http"

# Load environment
export $(cat .env.local | xargs)

# Start Jira server in background
echo "Starting Jira server on port 9001..."
mcp-atlassian --transport streamable-http --port 9001 -vv > jira-server.log 2>&1 &
JIRA_PID=$!

# Start Confluence server in background
echo "Starting Confluence server on port 9002..."
mcp-atlassian --transport streamable-http --port 9002 -vv > confluence-server.log 2>&1 &
CONFLUENCE_PID=$!

echo "Servers started!"
echo "Jira PID: $JIRA_PID (logs: jira-server.log)"
echo "Confluence PID: $CONFLUENCE_PID (logs: confluence-server.log)"
echo ""
echo "To view logs:"
echo "  tail -f jira-server.log"
echo "  tail -f confluence-server.log"
echo ""
echo "To stop servers:"
echo "  kill $JIRA_PID $CONFLUENCE_PID"
