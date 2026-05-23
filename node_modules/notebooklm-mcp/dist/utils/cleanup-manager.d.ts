/**
 * Cleanup Manager for NotebookLM MCP Server
 *
 * ULTRATHINK EDITION - Complete cleanup across all platforms!
 *
 * Handles safe removal of:
 * - Legacy data from notebooklm-mcp-nodejs
 * - Current installation data
 * - Browser profiles and session data
 * - NPM/NPX cache
 * - Claude CLI MCP logs
 * - Claude Projects cache
 * - Temporary backups
 * - Editor logs (Cursor, VSCode)
 * - Trash files (optional)
 *
 * Platform support: Linux, Windows, macOS
 */
export type CleanupMode = "legacy" | "all" | "deep";
export interface CleanupResult {
    success: boolean;
    mode: CleanupMode;
    deletedPaths: string[];
    failedPaths: string[];
    totalSizeBytes: number;
    categorySummary: Record<string, {
        count: number;
        bytes: number;
    }>;
}
export interface CleanupCategory {
    name: string;
    description: string;
    paths: string[];
    totalBytes: number;
    optional: boolean;
}
export declare class CleanupManager {
    private legacyPaths;
    private currentPaths;
    private homeDir;
    private tempDir;
    constructor();
    /**
     * Get NPM cache directory (platform-specific)
     */
    private getNpmCachePath;
    /**
     * Get Claude CLI cache directory (platform-specific)
     */
    private getClaudeCliCachePath;
    /**
     * Get Claude projects directory (platform-specific)
     */
    private getClaudeProjectsPath;
    /**
     * Get editor config paths (Cursor, VSCode)
     */
    private getEditorConfigPaths;
    /**
     * Get trash directory (platform-specific)
     */
    private getTrashPath;
    /**
     * Get manual legacy config paths that might not be caught by envPaths
     * This ensures we catch ALL legacy installations including old config.json files
     */
    private getManualLegacyPaths;
    /**
     * Find NPM/NPX cache files
     */
    private findNpmCache;
    /**
     * Find Claude CLI MCP logs
     */
    private findClaudeCliLogs;
    /**
     * Find Claude projects cache
     */
    private findClaudeProjects;
    /**
     * Find temporary backups
     */
    private findTemporaryBackups;
    /**
     * Find editor logs (Cursor, VSCode)
     */
    private findEditorLogs;
    /**
     * Find trash files
     */
    private findTrashFiles;
    /**
     * Get all paths that would be deleted for a given mode (with categorization)
     */
    getCleanupPaths(mode: CleanupMode, preserveLibrary?: boolean): Promise<{
        categories: CleanupCategory[];
        totalPaths: string[];
        totalSizeBytes: number;
    }>;
    /**
     * Perform cleanup with safety checks and detailed reporting
     */
    performCleanup(mode: CleanupMode, preserveLibrary?: boolean): Promise<CleanupResult>;
    /**
     * Check if a path exists
     */
    private pathExists;
    /**
     * Get the size of a single file
     */
    private getFileSize;
    /**
     * Get the total size of a directory (recursive)
     */
    private getDirectorySize;
    /**
     * Format bytes to human-readable string
     */
    formatBytes(bytes: number): string;
    /**
     * Get platform-specific path info
     */
    getPlatformInfo(): {
        platform: string;
        legacyBasePath: string;
        currentBasePath: string;
        npmCachePath: string;
        claudeCliCachePath: string;
        claudeProjectsPath: string;
    };
}
//# sourceMappingURL=cleanup-manager.d.ts.map