<script lang="ts">
  import type { PvalueColumnOptions } from "$types";

  interface Props {
    value: number | undefined | null;
    options?: PvalueColumnOptions;
  }

  let { value, options }: Props = $props();

  // Unicode superscript character mapping
  const SUPERSCRIPT_MAP: Record<string, string> = {
    "0": "⁰",
    "1": "¹",
    "2": "²",
    "3": "³",
    "4": "⁴",
    "5": "⁵",
    "6": "⁶",
    "7": "⁷",
    "8": "⁸",
    "9": "⁹",
    "-": "⁻",
    "+": "⁺",
  };

  function toSuperscript(str: string): string {
    return str
      .split("")
      .map((c) => SUPERSCRIPT_MAP[c] ?? c)
      .join("");
  }

  const showStars = $derived(options?.stars ?? false);
  const thresholds = $derived(options?.thresholds ?? [0.05, 0.01, 0.001]);
  const format = $derived(options?.format ?? "auto");
  const digits = $derived(options?.digits ?? 2);
  const expThreshold = $derived(options?.expThreshold ?? 0.001);

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

    // Very small values: show "less than" notation
    if (value < 0.0001) return "<0.0001";

    // Use scientific notation with Unicode superscript for small values
    if (format === "scientific" || (format === "auto" && value < expThreshold)) {
      const exp = Math.floor(Math.log10(value));
      const mantissa = value / Math.pow(10, exp);
      // Format mantissa to specified digits
      const mantissaStr = mantissa.toPrecision(digits);
      return `${mantissaStr}×10${toSuperscript(exp.toString())}`;
    }

    // Decimal format with appropriate precision based on magnitude
    if (value >= 0.1) return value.toFixed(digits);
    if (value >= 0.01) return value.toFixed(digits + 1);
    return value.toFixed(digits + 2);
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
