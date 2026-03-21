# MCP Gather Import (Sketch)

This is a minimal MCP server example that exposes one tool:

- `import_webpage_markdown`: convert a URL into markdown with `gather`

## Prerequisites

- `gather` installed and available on your `PATH`
- Node 18+

## Run locally

```bash
cd /Users/ttscoff/Desktop/Code/gather-cli/examples/mcp-gather-import
npm install
npm run start
```

## Cursor MCP config example

Add this server to your MCP config:

```json
{
  "mcpServers": {
    "gather-import": {
      "command": "node",
      "args": [
        "/Users/ttscoff/Desktop/Code/gather-cli/examples/mcp-gather-import/server.mjs"
      ]
    }
  }
}
```

## Tool input/output

Input:

```json
{
  "url": "https://example.com/article",
  "useFallback": false
}
```

Output (text JSON payload):

```json
{
  "url": "https://example.com/article",
  "markdown": "...",
  "used_fallback": false
}
```
