/**
 * Stealth utilities for human-like browser behavior
 *
 * This module provides functions to simulate realistic human interactions:
 * - Human-like typing (speed configurable via CONFIG.typingWpmMin/Max)
 * - Realistic mouse movements (Bezier curves with jitter)
 * - Random delays (normal distribution)
 * - Smooth scrolling
 * - Reading pauses
 *
 * Based on the Python implementation from stealth_utils.py
 */
import type { Page } from "patchright";
/**
 * Sleep for specified milliseconds
 */
export declare function sleep(ms: number): Promise<void>;
/**
 * Generate random integer between min and max (inclusive)
 */
export declare function randomInt(min: number, max: number): number;
/**
 * Generate random float between min and max
 */
export declare function randomFloat(min: number, max: number): number;
/**
 * Generate random character (for typos)
 */
export declare function randomChar(): string;
/**
 * Generate Gaussian (normal) distributed random number
 * Uses Box-Muller transform
 */
export declare function gaussian(mean: number, stdDev: number): number;
/**
 * Add a random delay to simulate human thinking/reaction time
 * Uses normal distribution for more realistic delays
 *
 * @param minMs Minimum delay in milliseconds (default: from CONFIG)
 * @param maxMs Maximum delay in milliseconds (default: from CONFIG)
 */
export declare function randomDelay(minMs?: number, maxMs?: number): Promise<void>;
/**
 * Type text in a human-like manner with variable speed and optional typos
 *
 * Simulates realistic typing patterns:
 * - Variable speed (45-65 WPM by default)
 * - Occasional typos (2% chance)
 * - Longer pauses after punctuation
 * - Realistic character delays
 *
 * @param page Playwright page instance
 * @param selector CSS selector of input element
 * @param text Text to type
 * @param options Typing options (wpm, withTypos)
 */
export declare function humanType(page: Page, selector: string, text: string, options?: {
    wpm?: number;
    withTypos?: boolean;
}): Promise<void>;
/**
 * Move mouse in a realistic curved path to target coordinates
 * Uses Bezier-like curves with jitter for natural movement
 *
 * @param page Playwright page instance
 * @param targetX Target X coordinate (default: random)
 * @param targetY Target Y coordinate (default: random)
 * @param steps Number of steps in movement (default: random 10-25)
 */
export declare function randomMouseMovement(page: Page, targetX?: number, targetY?: number, steps?: number): Promise<void>;
/**
 * Click an element with realistic human behavior
 * Includes mouse movement, pause, and click
 *
 * @param page Playwright page instance
 * @param selector CSS selector of element to click
 * @param withMouseMovement Whether to move mouse first (default: true)
 */
export declare function realisticClick(page: Page, selector: string, withMouseMovement?: boolean): Promise<void>;
/**
 * Scroll the page smoothly like a human
 * Uses multiple small steps for smooth animation
 *
 * @param page Playwright page instance
 * @param amount Scroll amount in pixels (default: random 100-400)
 * @param direction Scroll direction ("down" or "up")
 */
export declare function smoothScroll(page: Page, amount?: number, direction?: "up" | "down"): Promise<void>;
/**
 * Pause as if reading text, based on length
 * Calculates realistic reading time based on text length and WPM
 *
 * @param textLength Number of characters to "read"
 * @param wpm Reading speed in words per minute (default: random 200-250)
 */
export declare function readingPause(textLength: number, wpm?: number): Promise<void>;
/**
 * Add small random mouse movements to simulate natural fidgeting
 *
 * @param page Playwright page instance
 * @param iterations Number of small movements (default: 3)
 */
export declare function randomMouseJitter(page: Page, iterations?: number): Promise<void>;
/**
 * Hover over an element with realistic mouse movement
 *
 * @param page Playwright page instance
 * @param selector CSS selector of element to hover
 */
export declare function hoverElement(page: Page, selector: string): Promise<void>;
/**
 * Simulate reading a page with scrolling and pauses
 * Adds realistic behavior of scrolling and reading content
 *
 * @param page Playwright page instance
 */
export declare function simulateReadingPage(page: Page): Promise<void>;
declare const _default: {
    sleep: typeof sleep;
    randomInt: typeof randomInt;
    randomFloat: typeof randomFloat;
    randomChar: typeof randomChar;
    gaussian: typeof gaussian;
    randomDelay: typeof randomDelay;
    humanType: typeof humanType;
    randomMouseMovement: typeof randomMouseMovement;
    realisticClick: typeof realisticClick;
    smoothScroll: typeof smoothScroll;
    readingPause: typeof readingPause;
    randomMouseJitter: typeof randomMouseJitter;
    hoverElement: typeof hoverElement;
    simulateReadingPage: typeof simulateReadingPage;
};
export default _default;
//# sourceMappingURL=stealth-utils.d.ts.map