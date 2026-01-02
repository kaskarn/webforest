<script lang="ts">
  import type { Row, WebTheme, ComputedLayout, EffectSpec } from "$types";
  import type { ScaleLinear, ScaleLogarithmic } from "d3-scale";

  interface Props {
    row: Row;
    yPosition: number;
    xScale: ScaleLinear<number, number> | ScaleLogarithmic<number, number>;
    layout: ComputedLayout;
    theme: WebTheme | undefined;
    effects?: EffectSpec[];
    onRowClick?: () => void;
    onRowHover?: (hovered: boolean, event?: MouseEvent) => void;
  }

  let {
    row,
    yPosition,
    xScale,
    layout,
    theme,
    effects = [],
    onRowClick,
    onRowHover,
  }: Props = $props();

  // Helper to get numeric value from row (primary or metadata)
  function getValue(row: Row, colName: string, primary: "point" | "lower" | "upper"): number | null {
    // Check metadata first (for additional effects)
    const metaVal = row.metadata[colName];
    if (metaVal != null && typeof metaVal === "number" && !Number.isNaN(metaVal)) {
      return metaVal;
    }
    // Fall back to primary columns if colName matches
    if (colName === row.pointCol || primary === "point") return row.point;
    if (colName === row.lowerCol || primary === "lower") return row.lower;
    if (colName === row.upperCol || primary === "upper") return row.upper;
    return null;
  }

  // Compute effective effects to render
  // If no effects specified, create a default one from primary columns
  const effectsToRender = $derived.by(() => {
    if (effects.length === 0) {
      // Default effect from primary columns
      return [{
        id: "primary",
        pointCol: "point",
        lowerCol: "lower",
        upperCol: "upper",
        label: null,
        color: null,
        point: row.point,
        lower: row.lower,
        upper: row.upper,
      }];
    }

    // Map effects with resolved values
    return effects.map(effect => ({
      ...effect,
      point: getValue(row, effect.pointCol, "point"),
      lower: getValue(row, effect.lowerCol, "lower"),
      upper: getValue(row, effect.upperCol, "upper"),
    }));
  });

  // Vertical offset between multiple effects
  const EFFECT_SPACING = 6; // pixels between effects

  // Calculate vertical offset for each effect (centered around yPosition)
  function getEffectYOffset(index: number, total: number): number {
    if (total <= 1) return 0;
    const totalHeight = (total - 1) * EFFECT_SPACING;
    return -totalHeight / 2 + index * EFFECT_SPACING;
  }

  // Check if any effect has valid values
  const hasAnyValidValues = $derived(
    effectsToRender.some(e =>
      e.point != null && !Number.isNaN(e.point) &&
      e.lower != null && !Number.isNaN(e.lower) &&
      e.upper != null && !Number.isNaN(e.upper)
    )
  );

  // Check if this is a summary row (should render diamond instead of square)
  const isSummaryRow = $derived(row.style?.type === 'summary');

  // Diamond height for summary rows
  const diamondHeight = $derived(theme?.shapes.summaryHeight ?? 10);
  const halfDiamondHeight = $derived(diamondHeight / 2);

  // Point size scaled by weight if available
  const pointSize = $derived.by(() => {
    const baseSize = theme?.shapes.pointSize ?? 6;
    const weight = row.metadata.weight as number | undefined;
    if (weight) {
      // Scale between 0.5x and 2x based on weight
      const scale = 0.5 + Math.sqrt(weight / 100) * 1.5;
      return Math.min(Math.max(baseSize * scale, 3), baseSize * 2.5);
    }
    return baseSize;
  });

  // Get color for an effect
  function getEffectColor(effect: typeof effectsToRender[0]): string {
    // Use effect's specified color if available
    if (effect.color) return effect.color;

    // Fall back to theme-based coloring
    if (!theme) return "#2563eb";
    const nullValue = layout.nullValue;
    const point = effect.point ?? 0;
    return point > nullValue
      ? theme.colors.intervalPositive
      : point < nullValue
        ? theme.colors.intervalNegative
        : theme.colors.muted;
  }
</script>

{#if hasAnyValidValues}
  <g
    class="interval-row"
    role="button"
    tabindex="0"
    onclick={onRowClick}
    onmouseenter={(e) => onRowHover?.(true, e)}
    onmouseleave={(e) => onRowHover?.(false, e)}
    onkeydown={(e) => e.key === "Enter" && onRowClick?.()}
  >
    {#each effectsToRender as effect, idx}
      {@const hasValidEffect = effect.point != null && !Number.isNaN(effect.point) &&
                               effect.lower != null && !Number.isNaN(effect.lower) &&
                               effect.upper != null && !Number.isNaN(effect.upper)}
      {#if hasValidEffect}
        {@const effectY = yPosition + getEffectYOffset(idx, effectsToRender.length)}
        {@const x1 = xScale(effect.lower!)}
        {@const x2 = xScale(effect.upper!)}
        {@const cx = xScale(effect.point!)}
        {@const color = getEffectColor(effect)}
        {@const lineColor = effect.color ?? "var(--wf-interval-line, #475569)"}

        {#if isSummaryRow}
          <!-- Summary row: render diamond shape spanning lower to upper -->
          {@const diamondPoints = [
            `${x1},${effectY}`,           // left (lower)
            `${cx},${effectY - halfDiamondHeight}`,  // top (point)
            `${x2},${effectY}`,           // right (upper)
            `${cx},${effectY + halfDiamondHeight}`   // bottom (point)
          ].join(' ')}
          <polygon
            points={diamondPoints}
            fill="var(--wf-summary-fill, #2563eb)"
            stroke="var(--wf-summary-border, #1d4ed8)"
            stroke-width="1"
            class="point-estimate"
          />
        {:else}
          <!-- Regular row: CI line with whiskers and square point -->
          <!-- CI line -->
          <line
            {x1}
            {x2}
            y1={effectY}
            y2={effectY}
            stroke={lineColor}
            stroke-width={theme?.shapes.lineWidth ?? 1.5}
          />

          <!-- CI whiskers (caps) -->
          <line
            x1={x1}
            x2={x1}
            y1={effectY - 4}
            y2={effectY + 4}
            stroke={lineColor}
            stroke-width={theme?.shapes.lineWidth ?? 1.5}
          />
          <line
            x1={x2}
            x2={x2}
            y1={effectY - 4}
            y2={effectY + 4}
            stroke={lineColor}
            stroke-width={theme?.shapes.lineWidth ?? 1.5}
          />

          <!-- Point estimate (square) -->
          <rect
            x={cx - pointSize}
            y={effectY - pointSize}
            width={pointSize * 2}
            height={pointSize * 2}
            fill={color}
            class="point-estimate"
          />
        {/if}
      {/if}
    {/each}
  </g>
{/if}

<style>
  .interval-row {
    cursor: pointer;
    outline: none;
  }

  .interval-row:hover .point-estimate,
  .interval-row:focus .point-estimate {
    opacity: 0.8;
  }

  .point-estimate {
    transition: opacity 0.15s ease;
  }
</style>
