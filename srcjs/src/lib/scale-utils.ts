/**
 * Shared scale utilities for forest plots
 *
 * These functions are used by both the web-native Svelte renderer
 * and the pure-data SVG generator to ensure consistent axis scaling.
 */

/**
 * Round a domain to "nice" round numbers (similar to D3's scale.nice())
 * This makes axis ticks fall on round values like 0.5, 1, 2, 5, 10, etc.
 *
 * @param domain - The [min, max] domain to round
 * @param isLog - Whether this is for a log scale
 * @returns A new domain with nice round bounds
 */
export function niceDomain(
  domain: [number, number],
  isLog: boolean
): [number, number] {
  if (isLog) {
    // For log scale, use nice values: 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100...
    // This provides finer granularity than pure powers of 10
    const niceLogValues = [0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100];

    // Find nice min (largest nice value <= domain min)
    let niceMin = niceLogValues[0];
    for (const val of niceLogValues) {
      if (val <= domain[0]) niceMin = val;
      else break;
    }

    // Find nice max (smallest nice value >= domain max)
    let niceMax = niceLogValues[niceLogValues.length - 1];
    for (let i = niceLogValues.length - 1; i >= 0; i--) {
      if (niceLogValues[i] >= domain[1]) niceMax = niceLogValues[i];
      else break;
    }

    return [niceMin, niceMax];
  }

  // For linear scale, round to nice step intervals
  const span = domain[1] - domain[0];
  if (span === 0) return domain;

  // Find a nice step size (1, 2, 5, 10, 20, 50, etc.)
  const magnitude = Math.pow(10, Math.floor(Math.log10(span)));
  const normalized = span / magnitude;
  let step: number;
  if (normalized <= 1) step = magnitude * 0.1;
  else if (normalized <= 2) step = magnitude * 0.2;
  else if (normalized <= 5) step = magnitude * 0.5;
  else step = magnitude;

  const niceMin = Math.floor(domain[0] / step) * step;
  const niceMax = Math.ceil(domain[1] / step) * step;
  return [niceMin, niceMax];
}

/** Domain padding constant - how much extra space to add beyond data range */
export const DOMAIN_PADDING = 0.15;
