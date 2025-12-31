/**
 * Export utilities for forest plot static image generation
 */

import type { WebTheme } from "$types";

/**
 * Build CSS variable map from theme for inlining
 */
function buildCSSVarMap(theme: WebTheme): Record<string, string> {
  return {
    // Colors
    "--wf-bg": theme.colors.background,
    "--wf-fg": theme.colors.foreground,
    "--wf-primary": theme.colors.primary,
    "--wf-secondary": theme.colors.secondary,
    "--wf-accent": theme.colors.accent,
    "--wf-muted": theme.colors.muted,
    "--wf-border": theme.colors.border,
    "--wf-interval-positive": theme.colors.intervalPositive,
    "--wf-interval-negative": theme.colors.intervalNegative,
    "--wf-interval-neutral": theme.colors.intervalNeutral,
    "--wf-ci-line": theme.colors.intervalLine,
    "--wf-summary-fill": theme.colors.summaryFill,
    "--wf-summary-border": theme.colors.summaryBorder,
    // Typography
    "--wf-font-family": theme.typography.fontFamily,
    "--wf-font-size-sm": theme.typography.fontSizeSm,
    "--wf-font-size-base": theme.typography.fontSizeBase,
    "--wf-font-size-lg": theme.typography.fontSizeLg,
  };
}

/**
 * Inline CSS variables in an SVG element
 */
function inlineCSSVariables(element: Element, varMap: Record<string, string>): void {
  // Process all elements with style attributes containing var()
  const allElements = element.querySelectorAll("*");

  for (const el of [element, ...allElements]) {
    // Check inline style
    const style = el.getAttribute("style");
    if (style && style.includes("var(")) {
      let newStyle = style;
      for (const [varName, value] of Object.entries(varMap)) {
        // Replace var(--name) and var(--name, fallback) patterns
        const regex = new RegExp(`var\\(${varName}(?:,[^)]+)?\\)`, "g");
        newStyle = newStyle.replace(regex, value);
      }
      el.setAttribute("style", newStyle);
    }

    // Check common SVG attributes that might have CSS var references
    for (const attr of ["fill", "stroke", "color"]) {
      const value = el.getAttribute(attr);
      if (value && value.includes("var(")) {
        let newValue = value;
        for (const [varName, varValue] of Object.entries(varMap)) {
          const regex = new RegExp(`var\\(${varName}(?:,[^)]+)?\\)`, "g");
          newValue = newValue.replace(regex, varValue);
        }
        el.setAttribute(attr, newValue);
      }
    }
  }
}

/**
 * Get computed styles for an element
 */
function getComputedStyleValue(element: Element, property: string): string {
  return window.getComputedStyle(element).getPropertyValue(property);
}

/**
 * Clone and prepare SVG for export
 */
function prepareSVGForExport(svgElement: SVGSVGElement, theme: WebTheme): SVGSVGElement {
  // Clone the SVG
  const clone = svgElement.cloneNode(true) as SVGSVGElement;

  // Add XML namespace
  clone.setAttribute("xmlns", "http://www.w3.org/2000/svg");
  clone.setAttribute("xmlns:xlink", "http://www.w3.org/1999/xlink");

  // Inline CSS variables
  const varMap = buildCSSVarMap(theme);
  inlineCSSVariables(clone, varMap);

  // Set explicit dimensions from viewBox if not set
  if (!clone.getAttribute("width") || !clone.getAttribute("height")) {
    const viewBox = clone.getAttribute("viewBox");
    if (viewBox) {
      const [, , w, h] = viewBox.split(" ").map(Number);
      clone.setAttribute("width", String(w));
      clone.setAttribute("height", String(h));
    }
  }

  return clone;
}

/**
 * Serialize SVG element to string
 */
function serializeSVG(svgElement: SVGSVGElement): string {
  const serializer = new XMLSerializer();
  let svgString = serializer.serializeToString(svgElement);

  // Add XML declaration
  if (!svgString.startsWith("<?xml")) {
    svgString = '<?xml version="1.0" encoding="UTF-8"?>\n' + svgString;
  }

  return svgString;
}

/**
 * Export container as SVG string
 *
 * @param container - The webforest container element
 * @param theme - The WebTheme object for CSS variable resolution
 * @returns SVG string
 */
export function exportToSVG(container: HTMLElement, theme: WebTheme): string {
  const svg = container.querySelector("svg.webforest-canvas");
  if (!svg) {
    throw new Error("No SVG element found in container");
  }

  const preparedSVG = prepareSVGForExport(svg as SVGSVGElement, theme);
  return serializeSVG(preparedSVG);
}

/**
 * Export container as PNG blob
 *
 * @param container - The webforest container element
 * @param theme - The WebTheme object for CSS variable resolution
 * @param scale - Scale factor for resolution (default 2 for retina)
 * @returns Promise resolving to PNG Blob
 */
export async function exportToPNG(
  container: HTMLElement,
  theme: WebTheme,
  scale: number = 2
): Promise<Blob> {
  const svgString = exportToSVG(container, theme);

  return new Promise((resolve, reject) => {
    const img = new Image();
    const svgBlob = new Blob([svgString], { type: "image/svg+xml;charset=utf-8" });
    const url = URL.createObjectURL(svgBlob);

    img.onload = () => {
      const canvas = document.createElement("canvas");
      const ctx = canvas.getContext("2d");

      if (!ctx) {
        URL.revokeObjectURL(url);
        reject(new Error("Failed to get canvas context"));
        return;
      }

      canvas.width = img.width * scale;
      canvas.height = img.height * scale;

      // Fill with background color
      ctx.fillStyle = theme.colors.background;
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      // Scale and draw
      ctx.scale(scale, scale);
      ctx.drawImage(img, 0, 0);

      canvas.toBlob(
        (blob) => {
          URL.revokeObjectURL(url);
          if (blob) {
            resolve(blob);
          } else {
            reject(new Error("Failed to create PNG blob"));
          }
        },
        "image/png",
        1.0
      );
    };

    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("Failed to load SVG image"));
    };

    img.src = url;
  });
}

/**
 * Trigger file download in browser
 *
 * @param blob - The file blob to download
 * @param filename - The filename for the download
 */
export function triggerDownload(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

/**
 * Generate a default filename based on current timestamp
 *
 * @param extension - File extension (svg, png)
 * @returns Filename string
 */
export function generateFilename(extension: "svg" | "png"): string {
  const now = new Date();
  const timestamp = now.toISOString().slice(0, 19).replace(/[:-]/g, "");
  return `forest_plot_${timestamp}.${extension}`;
}
