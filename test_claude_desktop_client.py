#!/usr/bin/env python3
"""Test client simulating Claude Desktop with separate Jira and Confluence credentials."""

import asyncio
import json
import os
from mcp.client.streamable_http import streamablehttp_client
from mcp import ClientSession


# User's credentials from environment variables
JIRA_PAT_TOKEN = os.getenv("JIRA_PAT_TOKEN")
CONFLUENCE_BASIC_AUTH = os.getenv("CONFLUENCE_BASIC_AUTH")


async def test_service_specific_auth():
    """Test MCP server with service-specific authentication headers."""
    print("="*70)
    print("Claude Desktop Simulation - Service-Specific Authentication Test")
    print("="*70)

    port = 9001
    try:
        # Connect with service-specific auth headers
        async with streamablehttp_client(
            f"http://mcp-atlassian.spiliotis.net:{port}/mcp",
            headers={
                "X-Jira-Authorization": f"Token {JIRA_PAT_TOKEN}",
                "X-Confluence-Authorization": f"Basic {CONFLUENCE_BASIC_AUTH}",
            }
        ) as (read_stream, write_stream, _):
            async with ClientSession(read_stream, write_stream) as session:
                # Initialize
                print("\n1. Initializing connection...")
                init_result = await session.initialize()
                print(f"   ✓ Server: {init_result.serverInfo.name} v{init_result.serverInfo.version}")

                # List all tools
                print("\n2. Listing available tools...")
                tools_result = await session.list_tools()
                print(f"   ✓ Found {len(tools_result.tools)} tools")

                # Categorize tools
                jira_tools = [t for t in tools_result.tools if t.name.startswith('jira_')]
                confluence_tools = [t for t in tools_result.tools if t.name.startswith('confluence_')]

                print(f"\n   Available tools:")
                print(f"     - Jira tools: {len(jira_tools)}")
                print(f"     - Confluence tools: {len(confluence_tools)}")

                # Test Jira tool with Jira PAT
                print("\n3. Testing Jira tool (using X-Jira-Authorization with PAT)...")
                try:
                    result = await session.call_tool(
                        "jira_get_all_projects",
                        {}
                    )
                    print(f"   ✓ jira_get_all_projects called successfully")
                    if hasattr(result, 'content') and result.content:
                        content_str = str(result.content[0].text) if result.content else "No content"
                        # Parse JSON to see if we got actual data or an error
                        try:
                            data = json.loads(content_str)
                            if isinstance(data, list):
                                print(f"   Result: Found {len(data)} Jira projects")
                                if data:
                                    print(f"   First project: {data[0].get('key', 'N/A')} - {data[0].get('name', 'N/A')}")
                            else:
                                print(f"   Result (first 200 chars): {content_str[:200]}")
                        except json.JSONDecodeError:
                            preview = content_str[:300] + "..." if len(content_str) > 300 else content_str
                            print(f"   Result preview: {preview}")
                except Exception as e:
                    print(f"   ✗ jira_get_all_projects failed: {e}")

                # Test Confluence tool with Basic auth
                print("\n4. Testing Confluence tool (using X-Confluence-Authorization with Basic)...")
                try:
                    result = await session.call_tool(
                        "confluence_search",
                        {"query": "type=page", "limit": 5}
                    )
                    print(f"   ✓ confluence_search called successfully")
                    if hasattr(result, 'content') and result.content:
                        content_str = str(result.content[0].text) if result.content else "No content"
                        # Parse JSON to see if we got actual data or an error
                        try:
                            data = json.loads(content_str)
                            if isinstance(data, dict) and 'results' in data:
                                print(f"   Result: Found {len(data['results'])} Confluence pages")
                                if data['results']:
                                    print(f"   First page: {data['results'][0].get('title', 'N/A')}")
                            else:
                                print(f"   Result (first 200 chars): {content_str[:200]}")
                        except json.JSONDecodeError:
                            preview = content_str[:300] + "..." if len(content_str) > 300 else content_str
                            print(f"   Result preview: {preview}")
                except Exception as e:
                    print(f"   ✗ confluence_search failed: {e}")

                # Test with a Jira search query
                print("\n5. Testing Jira search (using PAT authentication)...")
                try:
                    result = await session.call_tool(
                        "jira_search",
                        {"jql": "project IS NOT EMPTY ORDER BY created DESC", "limit": 3}
                    )
                    print(f"   ✓ jira_search called successfully")
                    if hasattr(result, 'content') and result.content:
                        content_str = str(result.content[0].text) if result.content else "No content"
                        try:
                            data = json.loads(content_str)
                            if isinstance(data, dict) and 'issues' in data:
                                print(f"   Result: Found {len(data['issues'])} Jira issues")
                                for issue in data['issues'][:2]:
                                    print(f"     - {issue.get('key', 'N/A')}: {issue.get('fields', {}).get('summary', 'N/A')}")
                            else:
                                print(f"   Result (first 200 chars): {content_str[:200]}")
                        except json.JSONDecodeError:
                            preview = content_str[:300] + "..." if len(content_str) > 300 else content_str
                            print(f"   Result preview: {preview}")
                except Exception as e:
                    print(f"   ✗ jira_search failed: {e}")

                print("\n" + "="*70)
                print("Test completed!")
                print("="*70)

    except Exception as e:
        print(f"\n✗ Connection failed: {e}")
        import traceback
        traceback.print_exc()
        return 1

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(asyncio.run(test_service_specific_auth()))
