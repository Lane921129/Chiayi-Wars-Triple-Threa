/**
 * NotebookLM Library Manager
 *
 * Manages a persistent library of NotebookLM notebooks.
 * Allows Claude to autonomously add, remove, and switch between
 * multiple notebooks based on the task at hand.
 */
import type { NotebookEntry, AddNotebookInput, UpdateNotebookInput, LibraryStats } from "./types.js";
export declare class NotebookLibrary {
    private libraryPath;
    private library;
    constructor();
    /**
     * Load library from disk, or create default if not exists
     */
    private loadLibrary;
    /**
     * Create default library from current CONFIG
     */
    private createDefaultLibrary;
    /**
     * Save library to disk
     */
    private saveLibrary;
    /**
     * Generate a unique ID from a string (slug format)
     */
    private generateId;
    /**
     * Add a new notebook to the library
     */
    addNotebook(input: AddNotebookInput): NotebookEntry;
    /**
     * List all notebooks in library
     */
    listNotebooks(): NotebookEntry[];
    /**
     * Get a specific notebook by ID
     */
    getNotebook(id: string): NotebookEntry | null;
    /**
     * Get the currently active notebook
     */
    getActiveNotebook(): NotebookEntry | null;
    /**
     * Select a notebook as active
     */
    selectNotebook(id: string): NotebookEntry;
    /**
     * Update notebook metadata
     */
    updateNotebook(input: UpdateNotebookInput): NotebookEntry;
    /**
     * Remove notebook from library
     */
    removeNotebook(id: string): boolean;
    /**
     * Increment use count for a notebook
     */
    incrementUseCount(id: string): NotebookEntry | null;
    /**
     * Get library statistics
     */
    getStats(): LibraryStats;
    /**
     * Search notebooks by query (searches name, description, topics)
     */
    searchNotebooks(query: string): NotebookEntry[];
}
//# sourceMappingURL=notebook-library.d.ts.map