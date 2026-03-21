---
name: import-web-markdown-with-gather
description: >-
  Import web pages as clean markdown using the local gather CLI. Use when the
  user asks to fetch a URL as markdown, clip a page into notes, archive readable
  article text, or convert web content into markdown for context.
---

# Import Web Markdown With Gather

## Purpose

Use `gather` as the default local tool for converting a URL into readable markdown.

## Recommended Defaults

Run gather with these settings unless the user asks otherwise:

```bash
gather --metadata-yaml --inline-links --no-paragraph-links "<url>"
```

Rationale:

- `--metadata-yaml`: Adds title/date/source in front matter for downstream indexing.
- `--inline-links`: Keeps links close to text for RAG/chunk readability.
- `--no-paragraph-links`: Avoids repeated reference blocks after each paragraph.

## Required Workflow

1. Validate input:
   - Accept only `http://` or `https://` URLs.
   - If input is not a URL, ask for one.
2. Run gather:
   - Primary command:

     ```bash
     gather --metadata-yaml --inline-links --no-paragraph-links "<url>"
     ```

3. On failure, retry with fallback mode:
   - First fallback:

     ```bash
     gather --metadata-yaml --inline-links --no-paragraph-links \
       --no-readability "<url>"
     ```

   - If the page still fails and raw HTML is available, pass HTML directly:

     ```bash
     printf "%s" "$HTML" | gather --html --stdin --metadata-yaml \
       --inline-links --no-paragraph-links
     ```

4. Return markdown text as the main result.

## Output Contract

When successful, return:

- `url`: original URL
- `title`: extracted title when available
- `markdown`: full markdown body
- `used_fallback`: `true` if `--no-readability` or `--html` path was used

## Safety And Limits

- Do not execute JavaScript from pages.
- Do not follow login-only pages automatically.
- Preserve the original URL in output metadata.
- If output is empty or too short, report a partial extraction warning.

## Examples

Basic import:

```bash
gather --metadata-yaml --inline-links --no-paragraph-links "https://example.com/article"
```

Fallback when readability extraction fails:

```bash
gather --metadata-yaml --inline-links --no-paragraph-links --no-readability "https://example.com/article"
```

## Optional Variants

- Add title only:

  ```bash
  gather --title-only "<url>"
  ```

- Plain body without source/title injection:

  ```bash
  gather --no-include-source --no-include-title "<url>"
  ```
