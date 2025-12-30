<script lang="ts">
  import type { PvalueColumnOptions } from "$types";

  interface Props {
    value: number | undefined | null;
    options?: PvalueColumnOptions;
  }

  let { value, options }: Props = $props();

  const showStars = $derived(options?.stars ?? true);
  const thresholds = $derived(options?.thresholds ?? [0.05, 0.01, 0.001]);
  const format = $derived(options?.format ?? "auto");

  const stars = $derived.by(() => {
    if (!showStars || value === undefined || value === null) return "";
    const [t1, t2, t3] = thresholds;
    if (value < t3) return "***";
    if (value < t2) return "**";
    if (value < t1) return "*";
    return "";
  });

  const formattedValue = $derived.by(() => {
    if (value === undefined || value === null) return "";

    // Very small values: show < threshold
    if (value < 0.0001) return "<0.0001";

    // Use scientific notation for very small values
    if (format === "scientific" || (format === "auto" && value < 0.001)) {
      return value.toExponential(1);
    }

    // Decimal format
    if (value >= 0.1) return value.toFixed(2);
    if (value >= 0.01) return value.toFixed(3);
    return value.toFixed(4);
  });

  const isSignificant = $derived(stars.length > 0);
</script>

<span class="cell-pvalue" class:significant={isSignificant}>
  <span class="pvalue-number">{formattedValue}</span>
  {#if stars}
    <span class="pvalue-stars">{stars}</span>
  {/if}
</span>

<style>
  .cell-pvalue {
    display: inline-flex;
    align-items: baseline;
    gap: 1px;
    font-variant-numeric: tabular-nums;
  }

  .pvalue-number {
    font-size: inherit;
  }

  .pvalue-stars {
    font-size: 0.9em;
    color: var(--wf-interval-positive, #16a34a);
    font-weight: 600;
  }

  .significant .pvalue-number {
    font-weight: 500;
  }
</style>
