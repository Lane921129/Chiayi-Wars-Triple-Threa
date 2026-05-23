/**
 * Console logging utilities with colors and formatting
 * Similar to Python's rich.console
 */
const STYLES = {
    info: { prefix: "ℹ️", color: "\x1b[36m" }, // Cyan
    success: { prefix: "✅", color: "\x1b[32m" }, // Green
    warning: { prefix: "⚠️", color: "\x1b[33m" }, // Yellow
    error: { prefix: "❌", color: "\x1b[31m" }, // Red
    debug: { prefix: "🔍", color: "\x1b[35m" }, // Magenta
    dim: { prefix: "  ", color: "\x1b[2m" }, // Dim
};
const RESET = "\x1b[0m";
/**
 * Logger class for consistent console output
 */
export class Logger {
    enabled;
    constructor(enabled = true) {
        this.enabled = enabled;
    }
    /**
     * Log a message with a specific style
     */
    log(message, level = "info") {
        if (!this.enabled)
            return;
        const style = STYLES[level];
        const timestamp = new Date().toISOString().split("T")[1].slice(0, 8);
        const formattedMessage = `${style.color}${style.prefix}  [${timestamp}] ${message}${RESET}`;
        // Use stderr for logs to keep stdout clean for MCP JSON-RPC
        console.error(formattedMessage);
    }
    /**
     * Log info message
     */
    info(message) {
        this.log(message, "info");
    }
    /**
     * Log success message
     */
    success(message) {
        this.log(message, "success");
    }
    /**
     * Log warning message
     */
    warning(message) {
        this.log(message, "warning");
    }
    /**
     * Log error message
     */
    error(message) {
        this.log(message, "error");
    }
    /**
     * Log debug message
     */
    debug(message) {
        this.log(message, "debug");
    }
    /**
     * Log dim message (for less important info)
     */
    dim(message) {
        this.log(message, "dim");
    }
    /**
     * Enable or disable logging
     */
    setEnabled(enabled) {
        this.enabled = enabled;
    }
}
/**
 * Global logger instance
 */
export const logger = new Logger();
/**
 * Convenience functions for quick logging
 */
export const log = {
    info: (msg) => logger.info(msg),
    success: (msg) => logger.success(msg),
    warning: (msg) => logger.warning(msg),
    error: (msg) => logger.error(msg),
    debug: (msg) => logger.debug(msg),
    dim: (msg) => logger.dim(msg),
};
//# sourceMappingURL=logger.js.map