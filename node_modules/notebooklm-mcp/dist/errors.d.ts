/**
 * Custom Error Types for NotebookLM MCP Server
 */
/**
 * Error thrown when NotebookLM rate limit is exceeded
 *
 * Free users have 50 queries/day limit.
 * This error indicates the user should:
 * - Use re_auth tool to switch Google accounts
 * - Wait until tomorrow for quota reset
 * - Upgrade to Google AI Pro/Ultra for higher limits
 */
export declare class RateLimitError extends Error {
    constructor(message?: string);
}
/**
 * Error thrown when authentication fails
 *
 * This error can suggest cleanup workflow for persistent issues.
 * Especially useful when upgrading from old installation (notebooklm-mcp-nodejs).
 */
export declare class AuthenticationError extends Error {
    suggestCleanup: boolean;
    constructor(message: string, suggestCleanup?: boolean);
}
//# sourceMappingURL=errors.d.ts.map