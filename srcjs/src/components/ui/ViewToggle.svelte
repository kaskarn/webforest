<script lang="ts">
  import type { ForestStore } from "$stores/forestStore.svelte";

  interface Props {
    store: ForestStore;
  }

  let { store }: Props = $props();

  const includeForest = $derived(store.spec?.data?.includeForest ?? true);
</script>

<button
  class="view-toggle-btn"
  onclick={() => store.toggleForestView()}
  aria-label={includeForest ? "Show table only" : "Show forest plot"}
  title={includeForest ? "Show table only" : "Show forest plot"}
>
  {#if includeForest}
    <!-- Icon: combined forest + table view (default) -->
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <!-- Table lines on left -->
      <line x1="3" y1="6" x2="10" y2="6" />
      <line x1="3" y1="12" x2="10" y2="12" />
      <line x1="3" y1="18" x2="10" y2="18" />
      <!-- Forest plot on right -->
      <line x1="14" y1="12" x2="21" y2="12" />
      <circle cx="17" cy="12" r="2" fill="currentColor" />
    </svg>
  {:else}
    <!-- Icon: table only -->
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <line x1="3" y1="6" x2="21" y2="6" />
      <line x1="3" y1="12" x2="21" y2="12" />
      <line x1="3" y1="18" x2="21" y2="18" />
    </svg>
  {/if}
</button>

<style>
  .view-toggle-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    padding: 0;
    border: 1px solid var(--wf-border, #e2e8f0);
    border-radius: 6px;
    background: var(--wf-bg, #ffffff);
    color: var(--wf-secondary, #64748b);
    cursor: pointer;
    transition: background-color 0.15s ease, color 0.15s ease;
  }

  .view-toggle-btn:hover {
    background: var(--wf-border, #e2e8f0);
    color: var(--wf-fg, #1a1a1a);
  }
</style>
