/**
 * Arrow utilities for forest plot CI truncation indicators
 *
 * When confidence intervals extend beyond the axis limits, they are
 * clipped and arrow indicators show that the CI continues beyond
 * the visible range.
 *
 * This module provides:
 * - Arrow dimension computation based on theme line width
 * - SVG path generation for left/right arrows
 */

import type { WebTheme } from "../types";

export interface ArrowConfig {
  /** Arrow width in pixels (scales with line width) */
  width: number;
  /** Arrow height in pixels (scales with line width) */
  height: number;
  /** Arrow fill color */
  color: string;
  /** Arrow fill opacity (default 1.0) */
  opacity: number;
}

/**
 * Compute arrow dimensions based on theme settings
 *
 * Arrows scale with the line width to maintain visual consistency
 * across different themes (presentation, minimal, etc.)
 */
export function computeArrowDimensions(theme: WebTheme | null | undefined): ArrowConfig {
  const lineWidth = theme?.shapes?.lineWidth ?? 1.5;
  const color = theme?.colors?.intervalLine ?? "#475569";

  return {
    // Arrow width: 3x line width, minimum 4px
    width: Math.max(4, Math.round(lineWidth * 3)),
    // Arrow height: 4x line width, minimum 6px
    height: Math.max(6, Math.round(lineWidth * 4)),
    color,
    opacity: 1.0,
  };
}

/**
 * Generate SVG path for a truncation arrow
 *
 * @param direction - "left" for CI clipped on left, "right" for CI clipped on right
 * @param x - X position (left edge for left arrow, right edge for right arrow)
 * @param y - Y position (center of arrow)
 * @param config - Arrow configuration (dimensions and color)
 * @returns SVG path d attribute string
 */
export function renderArrowPath(
  direction: "left" | "right",
  x: number,
  y: number,
  config: ArrowConfig
): string {
  const { width, height } = config;
  const halfHeight = height / 2;

  if (direction === "left") {
    // Arrow pointing left: tip at x, body extends right
    // Shape: ◀
    //   Tip: (x, y)
    //   Top: (x + width, y - halfHeight)
    //   Bottom: (x + width, y + halfHeight)
    return `M ${x} ${y} L ${x + width} ${y - halfHeight} L ${x + width} ${y + halfHeight} Z`;
  } else {
    // Arrow pointing right: tip at x, body extends left
    // Shape: ▶
    //   Tip: (x, y)
    //   Top: (x - width, y - halfHeight)
    //   Bottom: (x - width, y + halfHeight)
    return `M ${x} ${y} L ${x - width} ${y - halfHeight} L ${x - width} ${y + halfHeight} Z`;
  }
}

/**
 * Check if a CI bound is clipped (extends beyond axis limits)
 *
 * @param value - The CI bound value (lower or upper)
 * @param axisLimits - The axis limits [min, max]
 * @returns "left" if clipped on left, "right" if clipped on right, null if not clipped
 */
export function getClipDirection(
  value: number,
  axisLimits: [number, number]
): "left" | "right" | null {
  if (value < axisLimits[0]) return "left";
  if (value > axisLimits[1]) return "right";
  return null;
}

/**
 * Clamp a value to axis limits for rendering
 */
export function clampToAxisLimits(value: number, axisLimits: [number, number]): number {
  return Math.max(axisLimits[0], Math.min(axisLimits[1], value));
}
