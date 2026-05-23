#!/usr/bin/env node
/**
 * NotebookLM MCP Server
 *
 * MCP Server for Google NotebookLM - Chat with Gemini 2.5 through NotebookLM
 * with session support and human-like behavior!
 *
 * Features:
 * - Session-based contextual conversations
 * - Auto re-login on session expiry
 * - Human-like typing and mouse movements
 * - Persistent browser fingerprint
 * - Stealth mode with Patchright
 * - Claude Code integration via npx
 *
 * Usage:
 *   npx notebooklm-mcp
 *   node dist/index.js
 *
 * Environment Variables:
 *   NOTEBOOK_URL - Default NotebookLM notebook URL
 *   AUTO_LOGIN_ENABLED - Enable automatic login (true/false)
 *   LOGIN_EMAIL - Google email for auto-login
 *   LOGIN_PASSWORD - Google password for auto-login
 *   HEADLESS - Run browser in headless mode (true/false)
 *   MAX_SESSIONS - Maximum concurrent sessions (default: 10)
 *   SESSION_TIMEOUT - Session timeout in seconds (default: 900)
 *
 * Based on the Python NotebookLM API implementation
 */
export {};
//# sourceMappingURL=index.d.ts.map