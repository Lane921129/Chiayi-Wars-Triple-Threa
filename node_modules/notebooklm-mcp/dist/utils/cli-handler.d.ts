/**
 * CLI Handler
 *
 * Handles CLI commands for configuration management.
 * Executed when the server is run with 'config' arguments.
 */
export declare class CliHandler {
    private settingsManager;
    constructor();
    handleCommand(args: string[]): Promise<void>;
    private handleSet;
    private handleGet;
    private handleReset;
    private printHelp;
}
//# sourceMappingURL=cli-handler.d.ts.map