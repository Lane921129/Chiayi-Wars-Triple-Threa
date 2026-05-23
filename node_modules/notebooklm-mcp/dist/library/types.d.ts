/**
 * NotebookLM Library Types
 *
 * Defines the structure for managing multiple NotebookLM notebooks
 * in a persistent library that Claude can manage autonomously.
 */
/**
 * Single notebook entry in the library
 */
export interface NotebookEntry {
    id: string;
    url: string;
    name: string;
    description: string;
    topics: string[];
    content_types: string[];
    use_cases: string[];
    added_at: string;
    last_used: string;
    use_count: number;
    tags?: string[];
}
/**
 * The complete notebook library
 */
export interface Library {
    notebooks: NotebookEntry[];
    active_notebook_id: string | null;
    last_modified: string;
    version: string;
}
/**
 * Input for adding a new notebook
 */
export interface AddNotebookInput {
    url: string;
    name: string;
    description: string;
    topics: string[];
    content_types?: string[];
    use_cases?: string[];
    tags?: string[];
}
/**
 * Input for updating a notebook
 */
export interface UpdateNotebookInput {
    id: string;
    name?: string;
    description?: string;
    topics?: string[];
    content_types?: string[];
    use_cases?: string[];
    tags?: string[];
    url?: string;
}
/**
 * Statistics about library usage
 */
export interface LibraryStats {
    total_notebooks: number;
    active_notebook: string | null;
    most_used_notebook: string | null;
    total_queries: number;
    last_modified: string;
}
//# sourceMappingURL=types.d.ts.map