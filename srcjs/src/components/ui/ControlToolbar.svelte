<script lang="ts">
  import type { ForestStore } from "$stores/forestStore.svelte";
  import ThemeSwitcher from "./ThemeSwitcher.svelte";
  import ViewToggle from "./ViewToggle.svelte";
  import DownloadButton from "./DownloadButton.svelte";

  interface Props {
    store: ForestStore;
    enableExport?: boolean;
    enableThemeSwitcher?: boolean;
    enableViewToggle?: boolean;
  }

  let {
    store,
    enableExport = true,
    enableThemeSwitcher = true,
    enableViewToggle = true,
  }: Props = $props();
</script>

<div class="control-toolbar">
  {#if enableThemeSwitcher}
    <ThemeSwitcher {store} />
  {/if}
  {#if enableViewToggle}
    <ViewToggle {store} />
  {/if}
  {#if enableExport}
    <DownloadButton {store} />
  {/if}
</div>

<style>
  .control-toolbar {
    position: absolute;
    top: 8px;
    right: 8px;
    z-index: 100;
    display: flex;
    flex-direction: row;
    gap: 4px;
  }

  /* Shared hover visibility for all buttons */
  .control-toolbar :global(button) {
    opacity: 0;
    transition: opacity 0.2s ease, background-color 0.15s ease, color 0.15s ease;
  }

  :global(.webforest-container:hover) .control-toolbar :global(button) {
    opacity: 1;
  }
</style>
