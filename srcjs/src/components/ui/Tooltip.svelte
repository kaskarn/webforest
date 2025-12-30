<script lang="ts">
  import type { Row, WebTheme } from "$types";

  interface Props {
    row: Row | null;
    position: { x: number; y: number } | null;
    fields?: string[] | null;
    theme?: WebTheme | undefined;
  }

  let { row, position, fields = null, theme }: Props = $props();

  // Format value for display
  function formatValue(value: unknown): string {
    if (value === null || value === undefined) return "—";
    if (typeof value === "number") {
      if (Number.isInteger(value)) return value.toString();
      return value.toFixed(3);
    }
    return String(value);
  }

  // Get fields to display
  const displayFields = $derived.by(() => {
    if (!row) return [];

    const entries = Object.entries(row.metadata);

    // If specific fields are requested, filter to those
    if (fields && fields.length > 0) {
      return entries.filter(([key]) => fields.includes(key));
    }

    // Otherwise show all non-internal fields
    return entries.filter(([key]) => !key.startsWith("_") && !key.startsWith("."));
  });

  // Compute position styles
  const positionStyle = $derived.by(() => {
    if (!position) return "";
    return `left: ${position.x + 10}px; top: ${position.y - 10}px;`;
  });
</script>

{#if row && position}
  <div class="webforest-tooltip" style={positionStyle}>
    <div class="tooltip-header">{row.label}</div>
    <div class="tooltip-body">
      <div class="tooltip-row tooltip-estimate">
        <span class="tooltip-label">Estimate</span>
        <span class="tooltip-value">
          {formatValue(row.point)} ({formatValue(row.lower)}, {formatValue(row.upper)})
        </span>
      </div>
      {#each displayFields as [key, value] (key)}
        <div class="tooltip-row">
          <span class="tooltip-label">{key}</span>
          <span class="tooltip-value">{formatValue(value)}</span>
        </div>
      {/each}
    </div>
  </div>
{/if}

<style>
  .webforest-tooltip {
    position: absolute;
    z-index: 1000;
    min-width: 180px;
    max-width: 300px;
    padding: 8px 12px;
    background: var(--wf-fg, #1a1a1a);
    color: var(--wf-bg, #fff);
    border-radius: 6px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    font-size: var(--wf-font-size-sm, 0.75rem);
    pointer-events: none;
    transform: translateY(-100%);
  }

  .tooltip-header {
    font-weight: 600;
    padding-bottom: 6px;
    margin-bottom: 6px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.2);
  }

  .tooltip-body {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .tooltip-row {
    display: flex;
    justify-content: space-between;
    gap: 12px;
  }

  .tooltip-row.tooltip-estimate {
    font-weight: 500;
  }

  .tooltip-label {
    color: rgba(255, 255, 255, 0.7);
  }

  .tooltip-value {
    font-variant-numeric: tabular-nums;
    text-align: right;
  }
</style>
