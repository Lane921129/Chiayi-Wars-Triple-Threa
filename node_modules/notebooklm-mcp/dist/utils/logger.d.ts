/**
 * Console logging utilities with colors and formatting
 * Similar to Python's rich.console
 */
type LogLevel = "info" | "success" | "warning" | "error" | "debug" | "dim";
/**
 * Logger class for consistent console output
 */
export declare class Logger {
    private enabled;
    constructor(enabled?: boolean);
    /**
     * Log a message with a specific style
     */
    log(message: string, level?: LogLevel): void;
    /**
     * Log info message
     */
    info(message: string): void;
    /**
     * Log success message
     */
    success(message: string): void;
    /**
     * Log warning message
     */
    warning(message: string): void;
    /**
     * Log error message
     */
    error(message: string): void;
    /**
     * Log debug message
     */
    debug(message: string): void;
    /**
     * Log dim message (for less important info)
     */
    dim(message: string): void;
    /**
     * Enable or disable logging
     */
    setEnabled(enabled: boolean): void;
}
/**
 * Global logger instance
 */
export declare const logger: Logger;
/**
 * Convenience functions for quick logging
 */
export declare const log: {
    info: (msg: string) => void;
    success: (msg: string) => void;
    warning: (msg: string) => void;
    error: (msg: string) => void;
    debug: (msg: string) => void;
    dim: (msg: string) => void;
};
export {};
//# sourceMappingURL=logger.d.ts.map