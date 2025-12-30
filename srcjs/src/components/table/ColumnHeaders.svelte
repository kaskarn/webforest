<script lang="ts">
  import type { ColumnDef, ColumnSpec, ColumnGroup } from "$types";

  interface Props {
    columnDefs: ColumnDef[];
    showLabel?: boolean;
    labelHeader?: string;
  }

  let { columnDefs, showLabel = false, labelHeader = "Label" }: Props = $props();

  // Compute if we have any groups (need two-row header)
  const hasGroups = $derived(columnDefs.some((c) => c.isGroup));

  // Get flat list of leaf columns
  function getLeafColumns(cols: ColumnDef[]): ColumnSpec[] {
    const result: ColumnSpec[] = [];
    for (const col of cols) {
      if (col.isGroup) {
        result.push(...getLeafColumns(col.columns));
      } else {
        result.push(col);
      }
    }
    return result;
  }

  // Get colspan for a column def
  function getColspan(col: ColumnDef): number {
    if (!col.isGroup) return 1;
    return getLeafColumns(col.columns).length;
  }

  const leafColumns = $derived(getLeafColumns(columnDefs));

  // Generate grid template columns for hierarchical layout
  const gridTemplateColumns = $derived.by(() => {
    if (!hasGroups) return "";
    const parts: string[] = [];
    if (showLabel) parts.push("minmax(120px, 1fr)");
    for (const col of leafColumns) {
      if (col.width) {
        parts.push(`${col.width}px`);
      } else {
        parts.push("auto");
      }
    }
    return parts.join(" ");
  });
</script>

{#if hasGroups}
  <!-- Two-row header for hierarchical columns using CSS Grid -->
  <div class="webforest-header-grid" style:grid-template-columns={gridTemplateColumns}>
    <!-- Row 1: Label + Group headers -->
    {#if showLabel}
      <div class="webforest-label-col header-cell group-row" style:grid-row="1 / 3">
        {labelHeader}
      </div>
    {/if}
    {#each columnDefs as col (col.id)}
      {#if col.isGroup}
        <div
          class="webforest-col header-cell group-header group-row"
          style:grid-column="span {getColspan(col)}"
        >
          {col.header}
        </div>
      {:else}
        <div
          class="webforest-col header-cell group-row"
          style:grid-row="1 / 3"
          style:text-align={col.align}
        >
          {col.header}
        </div>
      {/if}
    {/each}

    <!-- Row 2: Sub-column headers -->
    {#each columnDefs as col (col.id)}
      {#if col.isGroup}
        {#each col.columns as subCol (subCol.id)}
          {#if !subCol.isGroup}
            <div
              class="webforest-col header-cell column-row"
              style:text-align={subCol.align}
            >
              {subCol.header}
            </div>
          {/if}
        {/each}
      {/if}
    {/each}
  </div>
{:else}
  <!-- Single-row header for flat columns -->
  <div class="webforest-table-header">
    {#if showLabel}
      <div class="webforest-label-col">
        {labelHeader}
      </div>
    {/if}
    {#each leafColumns as column (column.id)}
      <div
        class="webforest-col"
        style:width={column.width ? `${column.width}px` : "auto"}
        style:text-align={column.align}
      >
        {column.header}
      </div>
    {/each}
  </div>
{/if}

<style>
  .webforest-table-header {
    display: flex;
    height: var(--wf-header-height);
    align-items: center;
    padding: 0 4px;
    background: var(--wf-bg);
    border-bottom: 1px solid var(--wf-border);
    font-weight: 600;
    font-size: var(--wf-font-size-sm);
    color: var(--wf-secondary);
  }

  .webforest-header-grid {
    display: grid;
    grid-template-rows: calc(var(--wf-header-height) / 2) calc(var(--wf-header-height) / 2);
    padding: 0 4px;
    background: var(--wf-bg);
    border-bottom: 1px solid var(--wf-border);
    font-weight: 600;
    font-size: var(--wf-font-size-sm);
    color: var(--wf-secondary);
  }

  .header-cell {
    display: flex;
    align-items: center;
  }

  .group-row {
    border-bottom: 1px solid var(--wf-border);
  }

  .column-row {
    /* No bottom border on column row - parent has it */
  }

  .group-header {
    justify-content: center;
    font-weight: 700;
  }

  .webforest-label-col {
    flex: 1;
    min-width: 120px;
    padding: 0 10px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .webforest-col {
    padding: 0 10px;
    font-variant-numeric: tabular-nums;
  }
</style>
