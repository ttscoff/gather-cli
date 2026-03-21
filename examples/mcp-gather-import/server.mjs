#!/usr/bin/env node
/**
 * Sketch MCP server wrapping gather CLI.
 *
 * Tool: import_webpage_markdown
 * Input: { url: string, useFallback?: boolean }
 * Output: { url, markdown, used_fallback }
 */

import { spawn } from "node:child_process";
import { z } from "zod";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new McpServer({
  name: "gather-import",
  version: "0.1.0",
});

const ImportArgs = z.object({
  url: z.string().url(),
  useFallback: z.boolean().optional().default(false),
});

function runGather(url, useFallback) {
  return new Promise((resolve, reject) => {
    const args = [
      "--metadata-yaml",
      "--inline-links",
      "--no-paragraph-links",
      ...(useFallback ? ["--no-readability"] : []),
      url,
    ];

    const proc = spawn("gather", args, { stdio: ["ignore", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";

    proc.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });

    proc.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });

    proc.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(stderr || `gather exited with code ${code}`));
        return;
      }
      resolve(stdout);
    });
  });
}

server.tool(
  "import_webpage_markdown",
  "Import a web page URL as markdown via gather CLI",
  {
    url: ImportArgs.shape.url,
    useFallback: ImportArgs.shape.useFallback,
  },
  async ({ url, useFallback = false }) => {
    const parsed = ImportArgs.safeParse({ url, useFallback });
    if (!parsed.success) {
      return {
        content: [{ type: "text", text: `Invalid input: ${parsed.error.message}` }],
        isError: true,
      };
    }

    try {
      const markdown = await runGather(parsed.data.url, parsed.data.useFallback);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                url: parsed.data.url,
                markdown,
                used_fallback: parsed.data.useFallback,
              },
              null,
              2
            ),
          },
        ],
      };
    } catch (error) {
      if (!parsed.data.useFallback) {
        try {
          const markdown = await runGather(parsed.data.url, true);
          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(
                  {
                    url: parsed.data.url,
                    markdown,
                    used_fallback: true,
                  },
                  null,
                  2
                ),
              },
            ],
          };
        } catch (fallbackError) {
          return {
            content: [
              {
                type: "text",
                text: `gather failed (normal + fallback): ${
                  fallbackError instanceof Error ? fallbackError.message : String(fallbackError)
                }`,
              },
            ],
            isError: true,
          };
        }
      }

      return {
        content: [
          {
            type: "text",
            text: `gather failed: ${error instanceof Error ? error.message : String(error)}`,
          },
        ],
        isError: true,
      };
    }
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
