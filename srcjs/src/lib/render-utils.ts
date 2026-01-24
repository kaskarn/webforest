/**
 * Shared rendering utilities for forest plots
 *
 * This module provides common logic used by both web components (Svelte)
 * and the SVG generator to ensure consistent rendering behavior.
 *
 * Key functions:
 * - computeEffectStyle: Resolves color/shape/opacity for effects
 * - computePointSize: Calculates point size with weight scaling
 * - computeClipping: Determines if CI bounds are clipped
 */

import type { Row, WebTheme, EffectSpec, MarkerShape } from "$types";

// ============================================================================
// Types
// ============================================================================

export interface EffectStyleResult {
  color: string;
  shape: MarkerShape;
  opacity: number;
}

export interface ClippingResult {
  clippedLeft: boolean;
  clippedRight: boolean;
  clampedLower: number;
  clampedUpper: number;
}

// Default shape sequence when no theme shapes specified
const DEFAULT_SHAPES: MarkerShape[] = ["square", "circle", "diamond", "triangle"];

// Default effect colors when no theme colors specified
const DEFAULT_EFFECT_COLORS = ["#2563eb", "#22c55e", "#f59e0b", "#ef4444", "#8b5cf6"];

// ============================================================================
// Effect Style Resolution
// ============================================================================

/**
 * Compute the visual style (color, shape, opacity) for an effect.
 *
 * Priority order for each property:
 * 1. Primary effect (idx=0): row.markerStyle (if set)
 * 2. effect spec (if set)
 * 3. theme defaults (cycling through arrays)
 * 4. hardcoded fallback
 *
 * @param effect - The effect specification
 * @param idx - Effect index (0 = primary)
 * @param row - Row data (for markerStyle)
 * @param theme - Theme configuration (optional)
 * @returns Resolved style with color, shape, opacity
 */
export function computeEffectStyle(
  effect: { color?: string | null; shape?: MarkerShape | null; opacity?: number | null },
  idx: number,
  row: Row,
  theme?: WebTheme
): EffectStyleResult {
  const isPrimary = idx === 0;
  const markerStyle = row.markerStyle;

  // Theme effect defaults
  const themeEffectColors = theme?.shapes?.effectColors ?? DEFAULT_EFFECT_COLORS;
  const themeMarkerShapes = theme?.shapes?.markerShapes;

  // Color priority
  let color: string;
  if (isPrimary && markerStyle?.color) {
    color = markerStyle.color;
  } else if (effect.color) {
    color = effect.color;
  } else if (themeEffectColors.length > 0) {
    color = themeEffectColors[idx % themeEffectColors.length];
  } else {
    color = theme?.colors?.interval ?? theme?.colors?.primary ?? "#2563eb";
  }

  // Shape priority
  let shape: MarkerShape;
  if (isPrimary && markerStyle?.shape) {
    shape = markerStyle.shape;
  } else if (effect.shape) {
    shape = effect.shape;
  } else if (themeMarkerShapes && themeMarkerShapes.length > 0) {
    shape = themeMarkerShapes[idx % themeMarkerShapes.length];
  } else {
    shape = DEFAULT_SHAPES[idx % DEFAULT_SHAPES.length];
  }

  // Opacity priority
  let opacity: number;
  if (isPrimary && markerStyle?.opacity != null) {
    opacity = markerStyle.opacity;
  } else if (effect.opacity != null) {
    opacity = effect.opacity;
  } else {
    opacity = 1;
  }

  return { color, shape, opacity };
}

// ============================================================================
// Point Size Computation
// ============================================================================

/**
 * Compute point size for an effect, with optional weight scaling.
 *
 * Supports:
 * - Row-level markerStyle.size (for primary effect)
 * - Legacy weight column scaling (0.5x to 2.5x)
 *
 * @param isPrimary - Whether this is the primary effect (idx=0)
 * @param row - Row data
 * @param basePointSize - Base point size from theme
 * @param weightCol - Optional weight column name
 * @returns Computed point size in pixels
 */
export function computePointSize(
  isPrimary: boolean,
  row: Row,
  basePointSize: number,
  weightCol?: string | null
): number {
  // Check row-level marker size (only for primary effect)
  if (isPrimary && row.markerStyle?.size != null) {
    return basePointSize * row.markerStyle.size;
  }

  // Legacy weight column support
  const weight = weightCol ? (row.metadata[weightCol] as number | undefined) : undefined;
  if (weight) {
    // Scale between 0.5x and 2.5x based on weight
    const scale = 0.5 + Math.sqrt(weight / 100) * 1.5;
    return Math.min(Math.max(basePointSize * scale, 3), basePointSize * 2.5);
  }

  return basePointSize;
}

// ============================================================================
// Clipping Detection
// ============================================================================

/**
 * Compute clipping for confidence interval bounds.
 *
 * Uses domain values (axis limits) rather than pixel coordinates
 * to determine if intervals extend beyond the visible axis range.
 *
 * @param lower - Lower bound of CI (domain units)
 * @param upper - Upper bound of CI (domain units)
 * @param clipBounds - Axis limits [min, max] (domain units)
 * @returns Clipping status and clamped values
 */
export function computeClipping(
  lower: number,
  upper: number,
  clipBounds: [number, number]
): ClippingResult {
  const [minBound, maxBound] = clipBounds;

  return {
    clippedLeft: lower < minBound,
    clippedRight: upper > maxBound,
    clampedLower: Math.max(minBound, Math.min(maxBound, lower)),
    clampedUpper: Math.max(minBound, Math.min(maxBound, upper)),
  };
}

/**
 * Check if a value is clipped at axis bounds.
 *
 * @param value - Value to check (domain units)
 * @param clipBounds - Axis limits [min, max] (domain units)
 * @returns "left" if clipped at min, "right" if clipped at max, null if not clipped
 */
export function getClipDirection(
  value: number,
  clipBounds: [number, number]
): "left" | "right" | null {
  if (value < clipBounds[0]) return "left";
  if (value > clipBounds[1]) return "right";
  return null;
}

/**
 * Clamp a value to axis bounds.
 *
 * @param value - Value to clamp (domain units)
 * @param clipBounds - Axis limits [min, max] (domain units)
 * @returns Clamped value
 */
export function clampToBounds(value: number, clipBounds: [number, number]): number {
  return Math.max(clipBounds[0], Math.min(clipBounds[1], value));
}
