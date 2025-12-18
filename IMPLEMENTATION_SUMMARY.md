# Implementation Summary: Service-Specific Authentication

## Intro

Implemented **service-specific authentication** for the MCP Atlassian server, allowing a single MCP endpoint to handle different authentication credentials for Jira and Confluence.

## Changes Made

### 1. Modified Middleware (`src/mcp_atlassian/servers/main.py`)

**Added:**
- `_parse_auth_header()` method to parse different authentication schemes (Bearer, Token, Basic)
- Support for new custom headers:
  - `X-Jira-Authorization` - Jira-specific authentication
  - `X-Confluence-Authorization` - Confluence-specific authentication
- Service-specific auth state storage in `request.state`:
  - `jira_auth_type`, `jira_token`, `jira_username`
  - `confluence_auth_type`, `confluence_token`, `confluence_username`

**Features:**
- Priority system: Service-specific headers override general `Authorization` header
- Backward compatibility: Still supports single `Authorization` header for both services
- Detailed debug logging for troubleshooting

### 2. Updated Dependency Functions (`src/mcp_atlassian/servers/dependencies.py`)

Modified `get_jira_fetcher()` and `get_confluence_fetcher()` to:
- Check for service-specific authentication first
- Fall back to general authentication if service-specific not provided
- Create user-specific fetchers with the appropriate credentials

### 3. Test Client (`test_claude_desktop_client.py`)

Created a comprehensive test client that:
- Simulates Claude Desktop's HTTP requests
- Uses separate authentication headers for Jira and Confluence
- Tests multiple tools from both services
- Validates that each service uses its own credentials

## Test Results

✅ **All tests passed successfully:**

```
1. Connection initialization - ✓ Success
2. Tool listing - ✓ Found 22 tools (16 Jira + 6 Confluence)
3. Jira authentication (PAT) - ✓ Retrieved 459 projects
4. Confluence authentication (Basic) - ✓ Successfully searched pages
5. Jira search (PAT) - ✓ Retrieved 3 issues
```

## How It Works

### Request Flow

1. **Claude/VSCode Desktop** sends request to `http://localhost:9001/mcp` with custom headers (or to a running container)
2. **UserTokenMiddleware** intercepts the request:
   - Parses `X-Jira-Authorization` header → stores in `request.state.jira_*`
   - Parses `X-Confluence-Authorization` header → stores in `request.state.confluence_*`
3. **Tool execution**:
   - Jira tools call `get_jira_fetcher()` → creates fetcher with Jira-specific auth
   - Confluence tools call `get_confluence_fetcher()` → creates fetcher with Confluence-specific auth
4. **API calls** use the appropriate credentials for each service

### Priority Order

For each service (Jira/Confluence):
1. Service-specific header (e.g., `X-Jira-Authorization`) - **Highest priority**
2. General `Authorization` header - **Fallback**
3. Environment variables - **Last resort**

## Files Modified

1. `src/mcp_atlassian/servers/main.py` - Middleware changes
2. `src/mcp_atlassian/servers/dependencies.py` - Fetcher dependency updates

## Files Created

1. `test_claude_desktop_client.py` - Test client
2. `CLAUDE_DESKTOP_CONFIG.md` - Configuration guide
3. `IMPLEMENTATION_SUMMARY.md` - This document

## Next Steps

### To Use in Production

1. **Start the MCP server** (keeps running in background):
   ```bash
   source .venv/bin/activate
   JIRA_URL=https://jira.sage.com \
   JIRA_SSL_VERIFY=false \
   CONFLUENCE_URL=https://intacct.atlassian.net \
   mcp-atlassian --transport streamable-http --port 9001 -vv > mcp-server.log 2>&1 &
   ```

2. **Configure Claude Desktop**:
   - Edit your `claude_desktop_config.json`
   - Add the configuration from above
   - Save the file

3. **Restart Claude Desktop** to load the new configuration

4. **Test it**:
   - Ask Claude: "Show me the list of Jira projects"
   - Ask Claude: "Search Confluence for pages about AR"
   - Verify both services respond correctly

### To Stop the Server

```bash
pkill -f "mcp-atlassian --transport streamable-http"
```

### To View Logs

```bash
tail -f mcp-server.log
```

## Benefits

1. **Single MCP endpoint** for both Jira and Confluence
2. **Different authentication** per service (PAT for Jira Server, Basic for Confluence Cloud)
3. **Backward compatible** with existing single-auth configurations
4. **Well-tested** with comprehensive test suite
5. **Detailed logging** for troubleshooting

## Architecture Diagram

```
Claude Desktop
    |
    | HTTP Request with headers:
    | - X-Jira-Authorization: Token <PAT>
    | - X-Confluence-Authorization: Basic <credentials>
    |
    v
UserTokenMiddleware (main.py)
    |
    ├─> Parse headers
    ├─> Store in request.state
    |   ├─> jira_auth_type = "pat"
    |   ├─> jira_token = <PAT>
    |   ├─> confluence_auth_type = "basic"
    |   └─> confluence_token = <api_token>
    |
    v
Tool Execution
    |
    ├─> Jira Tool Called
    |   └─> get_jira_fetcher() → Uses jira_* from request.state
    |       └─> JiraFetcher with PAT → Jira Server API
    |
    └─> Confluence Tool Called
        └─> get_confluence_fetcher() → Uses confluence_* from request.state
            └─> ConfluenceFetcher with Basic Auth → Confluence Cloud API
```

## Verification

Run the test to verify everything works:

```bash
source .venv/bin/activate
python test_claude_desktop_client.py
```

Expected output shows successful authentication and data retrieval for both services.
