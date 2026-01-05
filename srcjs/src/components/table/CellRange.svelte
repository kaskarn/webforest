<script lang="ts">
  import type { RangeColumnOptions } from "$types";

  interface Props {
    value: unknown;
    metadata: Record<string, unknown>;
    options?: RangeColumnOptions;
  }

  let { value, metadata, options }: Props = $props();

  const separator = $derived(options?.separator ?? " – ");
  const decimals = $derived(options?.decimals);
  const minField = $derived(options?.minField ?? "");
  const maxField = $derived(options?.maxField ?? "");

  // Get min and max values from metadata using configured field names
  const minValue = $derived.by(() => {
    if (!minField) return null;
    const val = metadata[minField];
    return typeof val === "number" ? val : null;
  });

  const maxValue = $derived.by(() => {
    if (!maxField) return null;
    const val = metadata[maxField];
    return typeof val === "number" ? val : null;
  });

  // Format a number with optional decimal precision
  function formatValue(val: number | null): string {
    if (val === null) return "";
    if (decimals === null || decimals === undefined) {
      // Auto mode: show integers without decimals, others with reasonable precision
      return Number.isInteger(val) ? String(val) : val.toFixed(1);
    }
    return val.toFixed(decimals);
  }

  const displayValue = $derived.by(() => {
    if (minValue === null && maxValue === null) return "";
    if (minValue === null) return formatValue(maxValue);
    if (maxValue === null) return formatValue(minValue);
    return `${formatValue(minValue)}${separator}${formatValue(maxValue)}`;
  });

  const hasRange = $derived(minValue !== null || maxValue !== null);
</script>

{#if hasRange}
  <span class="cell-range" title="{formatValue(minValue)} to {formatValue(maxValue)}">
    {displayValue}
  </span>
{/if}

<style>
  .cell-range {
    display: inline-block;
    white-space: nowrap;
    font-variant-numeric: tabular-nums;
  }
</style>
