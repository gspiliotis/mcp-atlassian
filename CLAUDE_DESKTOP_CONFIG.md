# Claude Desktop Configuration for MCP Atlassian

## Overview

The MCP Atlassian server now supports **service-specific authentication headers**, allowing you to provide different credentials for Jira and Confluence in a single MCP server configuration.

## Configuration

Add this to your `claude_desktop_config.json` file:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "http://localhost:9001/mcp",
        "--allow-http",
        "--header",
        "X-Jira-Authorization: Token YOUR_JIRA_PAT_TOKEN",
        "--header",
        "X-Confluence-Authorization: Basic YOUR_CONFLUENCE_BASIC_AUTH"
      ],
      "timeout": 30000
    }
  }
}
```

## Authentication Methods

### For Jira Server/Data Center (PAT Token)

Use the `X-Jira-Authorization` header with the `Token` scheme:

```
X-Jira-Authorization: Token YOUR_JIRA_PAT_TOKEN
```

Example:
```
X-Jira-Authorization: Token YOUR_JIRA_PAT
```

### For Confluence Cloud (Basic Auth)

Use the `X-Confluence-Authorization` header with the `Basic` scheme:

```
X-Confluence-Authorization: Basic BASE64_ENCODED_CREDENTIALS
```

Where `BASE64_ENCODED_CREDENTIALS` is the base64 encoding of `email:api_token`.

Example:
```
X-Confluence-Authorization: Basic YOUR_BASE64_CONFLUENCE_EMAIL_PAT
```

## Supported Authentication Schemes

Both headers support the following authentication schemes:

1. **Bearer** (OAuth 2.0): `Bearer YOUR_ACCESS_TOKEN`
2. **Token** (Personal Access Token): `Token YOUR_PAT_TOKEN`
3. **Basic** (Basic Authentication): `Basic BASE64_ENCODED_CREDENTIALS`

## Starting the MCP Server

Start the server on port 9001:

```bash
source .venv/bin/activate
mcp-atlassian --transport streamable-http --port 9001 -vv
```

Or use environment variables for minimal configuration:

```bash
JIRA_URL=https://jira.your-company.com \
JIRA_SSL_VERIFY=false \
CONFLUENCE_URL=https://your-company.atlassian.net \
READ_ONLY_MODE=true \
mcp-atlassian --transport streamable-http --port 9001 -vv
```

## Complete Example Configuration

Here's a complete working example for your use case (Jira Server with PAT, Confluence Cloud with Basic):

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "http://localhost:9001/mcp",
        "--allow-http",
        "--header",
        "X-Jira-Authorization: Token YOUR_JIRA_TOKEN",
        "--header",
        "X-Confluence-Authorization: Basic YOUR_BASE64_COMBINED_EMAIL_TOKEN"
      ],
      "timeout": 30000
    }
  }
}
```

## Testing the Configuration

You can test the configuration using the provided test client:

```bash
source .venv/bin/activate
python test_claude_desktop_client.py
```

Expected output:
- ✓ Jira tools should successfully retrieve projects and issues using PAT authentication
- ✓ Confluence tools should successfully search pages using Basic authentication

## Available Tools

### Jira Tools (16)
- `jira_get_all_projects` - Get all accessible Jira projects
- `jira_search` - Search issues using JQL
- `jira_get_issue` - Get details of a specific issue
- `jira_get_transitions` - Get available status transitions
- And 12 more...

### Confluence Tools (6)
- `confluence_search` - Search Confluence content
- `confluence_get_page` - Get a specific page
- `confluence_get_page_children` - Get child pages
- `confluence_get_comments` - Get page comments
- And 2 more...

## Backward Compatibility

The server still supports the legacy single `Authorization` header for cases where both Jira and Confluence use the same authentication:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "http://localhost:9001/mcp",
        "--allow-http",
        "--header",
        "Authorization: Token YOUR_SHARED_TOKEN"
      ]
    }
  }
}
```

## Troubleshooting

### Check Server Logs

The server logs detailed authentication information. Check `mcp-server.log`:

```bash
tail -f mcp-server.log | grep -i "auth\|error"
```

### Verify Authentication

Look for log entries like:
- `Jira service-specific auth: type=pat` - Confirms Jira auth was detected
- `Confluence service-specific auth: type=basic` - Confirms Confluence auth was detected
- `401 Unauthorized` - Authentication failed, check credentials

### Common Issues

1. **Base64 encoding for Basic auth**: Make sure your Confluence credentials are properly base64 encoded
   ```bash
   echo -n "your.email@company.com:YOUR_API_TOKEN" | base64
   ```

2. **PAT Token format**: Jira Server PAT tokens don't need additional encoding, use them as-is

3. **SSL Verification**: If using self-signed certificates for Jira Server, set `JIRA_SSL_VERIFY=false`

## Next Steps

1. Stop the test server:
   ```bash
   pkill -f "mcp-atlassian --transport streamable-http"
   ```

2. Start the server for production use
3. Configure Claude Desktop with your credentials
4. Restart Claude Desktop to load the new configuration
