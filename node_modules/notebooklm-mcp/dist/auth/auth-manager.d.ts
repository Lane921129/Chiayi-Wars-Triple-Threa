/**
 * Authentication Manager for NotebookLM
 *
 * Handles:
 * - Interactive login (headful browser for setup)
 * - Auto-login with credentials (email/password from ENV)
 * - Browser state persistence (cookies + localStorage + sessionStorage)
 * - Cookie expiry validation
 * - State expiry checks (24h file age)
 * - Hard reset for clean start
 *
 * Based on the Python implementation from auth.py
 */
import type { BrowserContext, Page } from "patchright";
import type { ProgressCallback } from "../types.js";
export declare class AuthManager {
    private stateFilePath;
    private sessionFilePath;
    constructor();
    /**
     * Save entire browser state (cookies + localStorage)
     */
    saveBrowserState(context: BrowserContext, page?: Page): Promise<boolean>;
    /**
     * Check if saved browser state exists
     */
    hasSavedState(): Promise<boolean>;
    /**
     * Get path to saved browser state
     */
    getStatePath(): string | null;
    /**
     * Get valid state path (checks expiry)
     */
    getValidStatePath(): Promise<string | null>;
    /**
     * Load sessionStorage from file
     */
    loadSessionStorage(): Promise<Record<string, string> | null>;
    /**
     * Validate if saved state is still valid
     */
    validateState(context: BrowserContext): Promise<boolean>;
    /**
     * Validate if critical authentication cookies are still valid
     */
    validateCookiesExpiry(context: BrowserContext): Promise<boolean>;
    /**
     * Check if the saved state file is too old (>24 hours)
     */
    isStateExpired(): Promise<boolean>;
    /**
     * Perform interactive login
     * User will see a browser window and login manually
     *
     * SIMPLE & RELIABLE: Just wait for URL to change to notebooklm.google.com
     */
    performLogin(page: Page, sendProgress?: ProgressCallback): Promise<boolean>;
    /**
     * Attempt to authenticate using configured credentials
     */
    loginWithCredentials(context: BrowserContext, page: Page, email: string, password: string): Promise<boolean>;
    /**
     * Wait for Google to redirect to NotebookLM after successful login (SIMPLE & RELIABLE)
     *
     * Just checks if URL changes to notebooklm.google.com - no complex UI element searching!
     * Matches the simplified approach used in performLogin().
     */
    private waitForRedirectAfterLogin;
    /**
     * Wait for NotebookLM to load (SIMPLE & RELIABLE)
     *
     * Just checks if URL starts with notebooklm.google.com - no complex UI element searching!
     * Matches the simplified approach used in performLogin().
     */
    private waitForNotebook;
    /**
     * Handle possible account chooser
     */
    private handleAccountChooser;
    /**
     * Fill email identifier field with human-like typing
     */
    private fillIdentifier;
    /**
     * Fill password field with human-like typing
     */
    private fillPassword;
    /**
     * Click text element
     */
    private clickText;
    /**
     * Mask email for logging
     */
    private maskEmail;
    /**
     * Load authentication state from a specific file path
     */
    loadAuthState(context: BrowserContext, statePath: string): Promise<boolean>;
    /**
     * Perform interactive setup (for setup_auth tool)
     * Opens a PERSISTENT browser for manual login
     *
     * CRITICAL: Uses the SAME persistent context as runtime!
     * This ensures cookies are automatically saved to the Chrome profile.
     *
     * Benefits over temporary browser:
     * - Session cookies persist correctly (Playwright bug workaround)
     * - Same fingerprint as runtime
     * - No need for addCookies() workarounds
     * - Automatic cookie persistence via Chrome profile
     *
     * @param sendProgress Optional progress callback
     * @param overrideHeadless Optional override for headless mode (true = visible, false = headless)
     *                         If not provided, defaults to true (visible) for setup
     */
    performSetup(sendProgress?: ProgressCallback, overrideHeadless?: boolean): Promise<boolean>;
    /**
     * Clear ALL authentication data for account switching
     *
     * CRITICAL: This deletes EVERYTHING to ensure only ONE account is active:
     * - All state.json files (cookies, localStorage)
     * - sessionStorage files
     * - Chrome profile directory (browser fingerprint, cache, etc.)
     *
     * Use this BEFORE authenticating a new account!
     */
    clearAllAuthData(): Promise<void>;
    /**
     * Clear all saved authentication state
     */
    clearState(): Promise<boolean>;
    /**
     * HARD RESET: Completely delete ALL authentication state
     */
    hardResetState(): Promise<boolean>;
}
//# sourceMappingURL=auth-manager.d.ts.map