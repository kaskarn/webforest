# WebForest Future Directions

> Strategic planning document for webforest development priorities.
> Last updated: 2026-01-16

## Current State Summary

WebForest is a mature forest plot package with:
- **Rich R data model**: S7 classes, formula evaluation, column expressions
- **Interactive frontend**: Svelte 5, hover/click/select/filter/sort/collapse
- **Publication theming**: 9 presets (JAMA, Lancet, Nature, Cochrane, etc.)
- **Export**: SVG, PDF, PNG
- **Shiny integration**: Reactive proxy updates

---

## Proposed Directions

### 1. Interactive Styling Interface

**Concept**: On-hover toolbar allowing users to style cells/rows/columns visually (colors, bold, badges) without writing R code.

**Design sketch**:
```
┌─────────────────────────────────────────┐
│ Study          │ OR (95% CI)   │ [plot] │
├─────────────────────────────────────────┤
│ Smith 2020 [🎨]│ 1.25 (0.8-1.9)│   ●──  │  ← hover shows toolbar
│    ┌──────────────────────┐             │
│    │ [B] [I] [🔴🟢🔵] [📌] │             │  ← inline style toolbar
│    └──────────────────────┘             │
```

**Technical approach**:
- Toolbar component appears on hover (Svelte)
- Actions dispatch to store, update row/cell metadata
- "Export styles" button generates R code snippet
- Optional: persist to localStorage for session continuity

**Cost**: HIGH
- Complex UI (color picker, icon selector)
- State synchronization challenges
- Code generation for reproducibility
- Accessibility considerations for toolbar

**Benefit**: MEDIUM-HIGH
- Great for exploration/prototyping
- Lowers barrier for non-programmers
- But: most users are R programmers who prefer code

**Priority**: LOW - Nice to have, not core to package value

---

### 2. Improved Resizing & Rescaling

**Concept**: Better UX for resizing columns, forest plot area, and overall widget with intuitive drag handles and responsive behavior.

**Current limitations**:
- Column resize exists but can feel clunky
- Forest area resize triggers full re-render
- No persistence of user adjustments

**Design sketch**:
```
┌────────────────────────────────────────────────────┐
│ Study     ⋮│ OR        ⋮│ ←──── Forest ────→ ⋮│ P  │
│           ⋮│           ⋮│        [drag]       ⋮│    │
├───────────┴────────────┴──────────────────────┴────┤
│ Total width: [━━━━━━━●━━━━━] 900px                 │  ← slider
└────────────────────────────────────────────────────┘
```

**Technical approach**:
- Improve drag handle visibility/feedback
- Add forest area resize handle (not just columns)
- Debounced axis recalculation during resize
- Persist widths to spec or localStorage
- "Reset to auto" button

**Cost**: MEDIUM
- Enhance existing infrastructure
- UX design for handles/feedback
- State persistence decisions

**Benefit**: HIGH
- Core interaction, used constantly
- Better fit to various container sizes
- Professional feel

**Priority**: MEDIUM-HIGH - Worth doing well

---

### 3. Export Formats: Markdown, XML, PPTX

**Concept**: Additional export formats beyond raster/vector graphics.

**Formats**:
| Format | Use Case | Complexity |
|--------|----------|------------|
| Markdown | Plain text, Git-friendly, accessibility | LOW |
| HTML table | Email, web embedding | LOW |
| CSV/TSV | Data extraction | LOW |
| XML | Interoperability, archival | LOW |
| PPTX | Presentations, Office workflows | MEDIUM |
| DOCX | Word integration | MEDIUM |

**Design sketch** (Markdown output):
```markdown
| Study | OR (95% CI) | Forest |
|-------|-------------|--------|
| **Smith 2020** | 1.25 (0.80, 1.95) | ●── |
| Jones 2021 | 0.89 (0.65, 1.22) | ──● |
| **Overall** | 1.05 (0.88, 1.25) | ◆ |
```

**Technical approach**:
- Table-only formats: extract from spec data, format strings
- PPTX: use `officer` package, embed SVG or convert to EMF
- Add `save_table(spec, file, format = "markdown")` function
- Consider ASCII art forest for plain text (fun but low priority)

**Cost**: LOW-MEDIUM
- Markdown/CSV: trivial
- PPTX/DOCX: moderate (officer dependency, layout)

**Benefit**: MEDIUM
- PPTX highly requested for presentations
- Markdown good for documentation/Git
- Niche but valuable for specific workflows

**Priority**: MEDIUM - PPTX would be high-value addition

---

### 4. New Plot Types: Boxplots, Density Plots

**Concept**: Beyond point+CI, show full distributions for each row.

**Visual options**:
```
Point + CI (current):     ├────●────┤
Boxplot:                  ├─┬─█─┬─┤
Violin/density:           ╭──█──╮
Dot plot:                 ·· ··●·· ··
Gradient bar:             ▓▓▓██▓▓▓
```

**Design sketch**:
```r
forest_plot(data,
  plot_type = "boxplot",  # or "violin", "dots", "gradient"
  q1 = "q1", q3 = "q3", median = "median",  # for boxplot
  # or
  distribution = "dist_col"  # column containing distribution data
)
```

**Technical approach**:
- New plot_type parameter in spec
- Additional data columns for distribution quantiles
- SVG rendering for new shapes
- Handle mixed types? (some rows point+CI, some boxplot)

**Cost**: HIGH
- New data model for distributions
- Significant SVG rendering work
- Space constraints in forest area
- Scale calculation changes

**Benefit**: MEDIUM-HIGH
- Richer visualization of uncertainty
- Differentiator from other packages
- Useful for Bayesian posteriors, simulation results

**Priority**: MEDIUM - Valuable but significant investment

---

### 5. Embedded Subtables (Expandable Rows)

**Concept**: Click a row to reveal a sub-table or sub-plot below it, enabling drill-down exploration.

**Design sketch**:
```
┌─────────────────────────────────────────────────┐
│ Region A        │ 1.15 (0.95, 1.40) │   ●──    │
│ ▼ Smith 2020    │ 1.25 (0.80, 1.95) │   ●──    │  ← click to expand
│   ┌─────────────────────────────────────────┐  │
│   │ Subgroup    │ OR       │ [mini-forest]  │  │  ← embedded subtable
│   │ Male        │ 1.30     │     ●──        │  │
│   │ Female      │ 1.18     │    ●──         │  │
│   └─────────────────────────────────────────┘  │
│   Jones 2021    │ 0.89 (0.65, 1.22) │  ──●    │
```

**R interface options**:
```r
# Option A: Explicit embed specification
forest_plot(data, ...,
  embed = embed_spec(
    parent_col = "study",
    child_data = subgroup_data,
    match_by = "study_id"
  )
)

# Option B: Nested data frame column
data$subgroups <- list(df1, df2, df3, NULL, ...)
forest_plot(data, ..., embed_col = "subgroups")

# Option C: Flag column approach
forest_plot(combined_data, ...,
  embed_flag = "is_subgroup",  # TRUE = hidden child row
  embed_parent = "parent_id"   # links child to parent
)
```

**Technical approach**:
- New row type: "expandable" with children
- Recursive WebSpec or nested row structure
- Animation for expand/collapse
- Shared vs independent axis for subtable
- Handle arbitrary depth? (probably limit to 1-2 levels)

**Cost**: HIGH
- Significant data model changes
- Complex UI interactions
- State management for expand/collapse
- Layout calculations with dynamic height

**Benefit**: HIGH
- Powerful drill-down capability
- Hides complexity until needed
- Unique feature among forest plot packages

**Priority**: MEDIUM-HIGH - High value, high cost

---

### 6. Interactive Column/Row Reordering

**Concept**: Drag-and-drop to reorder columns and rows.

**Design sketch**:
```
┌────────────────────────────────────────┐
│ Study  ↕│ OR     ↕│ P-value ↕│ [plot] │  ← drag column headers
├────────────────────────────────────────┤
│ ≡ Smith │ 1.25   │ 0.032    │  ●──   │  ← drag row handles
│ ≡ Jones │ 0.89   │ 0.156    │ ──●    │
```

**Technical approach**:
- Use Svelte drag-drop (svelte-dnd-action or similar)
- Column reorder: update columnOrder in store
- Row reorder: update data order (manual sort)
- Visual feedback during drag
- Persist order to spec or export as R code

**Cost**: MEDIUM
- Drag-drop library integration
- State management for order
- Handle grouped rows (drag group vs individual)

**Benefit**: MEDIUM
- Good for exploration
- But: sorting usually preferred over manual reorder
- Column reorder more valuable than row reorder

**Priority**: LOW-MEDIUM - Column reorder useful; row reorder niche

---

### 7. Enhanced Filtering & Sorting

**Concept**: More powerful filter UI, multi-column sort, saved filter presets.

**Current state**: Basic sort (single column), filter exists but limited UI.

**Enhancements**:
```
┌─ Filters ──────────────────────────────┐
│ Study: [contains    ▼] [________]      │
│ OR:    [between     ▼] [0.5] - [2.0]   │
│ P:     [less than   ▼] [0.05]          │
│ Region: [☑ Americas] [☑ Europe] [☐ Asia]│
│                                        │
│ Sort: OR ↑, then P-value ↓             │
│ [Save preset ▼] [Clear all]            │
└────────────────────────────────────────┘
```

**Technical approach**:
- Filter panel component with type-aware inputs
- Multi-column sort with priority
- Filter presets saved to localStorage or spec
- URL query param integration for sharing

**Cost**: MEDIUM
- UI components for filter types
- Multi-sort logic (exists partially)
- Preset storage/retrieval

**Benefit**: HIGH
- Essential for large datasets
- Power users expect this
- Improves data exploration significantly

**Priority**: HIGH - Core interactive feature

---

## Additional Suggested Directions

### 8. Linked Brushing / Coordinated Views

**Concept**: Select rows in one forest plot, highlight corresponding rows in another (split forests, Shiny dashboards).

**Design sketch**:
```
┌─ Region: Americas ─────┐    ┌─ Region: Europe ──────┐
│ Smith [selected]  ●──  │    │ Smith [highlighted]●──│
│ Jones             ──●  │    │ Jones            ──●  │
└────────────────────────┘    └────────────────────────┘
```

**Technical approach**:
- Shared selection store across widgets
- Shiny: use reactive values
- Standalone: custom events or shared context
- Match rows by ID or key column

**Cost**: MEDIUM
- Cross-widget communication
- ID matching logic
- Visual feedback for "linked highlight" vs "selected"

**Benefit**: HIGH
- Powerful for comparative analysis
- Expected in modern visualization tools
- Differentiator feature

**Priority**: MEDIUM-HIGH - Valuable for split forests & Shiny

---

### 9. Animations & Transitions

**Concept**: Smooth transitions when sorting, filtering, expanding, or updating data.

**Examples**:
- Rows slide into new positions when sorted
- Rows fade in/out when filtered
- Groups expand/collapse with accordion animation
- Data updates crossfade

**Technical approach**:
- Svelte `transition:` and `animate:` directives
- FLIP animations for reordering
- Configurable: `theme$animation = TRUE/FALSE`
- Respect `prefers-reduced-motion`

**Cost**: LOW-MEDIUM
- Svelte has excellent animation support
- Need to identify all transition points
- Performance testing with large datasets

**Benefit**: MEDIUM
- Professional, polished feel
- Helps users track changes
- But: some users prefer instant updates

**Priority**: MEDIUM - Polish feature, not critical

---

### 10. Accessibility Improvements

**Concept**: Screen reader support, keyboard navigation, ARIA labels, high contrast.

**Current issues** (from build warnings):
- Non-interactive elements with click handlers
- Missing ARIA roles
- Tabindex on non-interactive elements

**Improvements needed**:
- Semantic HTML (buttons, not divs)
- ARIA labels for forest plot elements
- Keyboard navigation (arrow keys, Enter, Escape)
- Focus indicators
- High contrast theme option
- Alt text for exported images

**Cost**: MEDIUM
- Systematic audit required
- Some refactoring of interactive elements
- Testing with screen readers

**Benefit**: HIGH
- Inclusive design
- May be required for government/academic use
- Improves keyboard-only users experience
- SEO benefits for web deployment

**Priority**: HIGH - Important for professional package

---

### 11. Custom Cell Renderers / Plugin System

**Concept**: Allow users to define custom column types with their own rendering logic.

**Design sketch**:
```r
# R side: register custom renderer
register_column_renderer("heatmap", function(value, row, theme) {
  # Return SVG or HTML string
})

# Usage
forest_plot(data, columns = list(
  web_column("expression", type = "heatmap", ...)
))
```

**Technical approach**:
- R: renderer registry, serialization of custom content
- JS: safe HTML injection or Svelte component slots
- Sandboxing concerns for arbitrary JS
- Documentation & examples for extension

**Cost**: HIGH
- Security considerations (XSS)
- API design complexity
- Documentation burden

**Benefit**: MEDIUM
- Infinite extensibility
- But: current column types cover most needs
- Niche advanced use case

**Priority**: LOW - Over-engineering risk

---

### 12. Statistical Annotations

**Concept**: Auto-calculate and display common meta-analysis statistics.

**Statistics**:
- Heterogeneity: I², τ², Q statistic, p-value
- Subgroup tests: Q-between, interaction p-value
- Prediction intervals
- Egger's test for publication bias

**Design sketch**:
```
┌─────────────────────────────────────────────────┐
│ Study          │ OR (95% CI)     │   [forest]   │
├─────────────────────────────────────────────────┤
│ ...            │ ...             │   ...        │
│ **Overall**    │ 1.05 (0.88-1.25)│      ◆       │
├─────────────────────────────────────────────────┤
│ Heterogeneity: I² = 45%, τ² = 0.02, p = 0.08   │
│ Test for overall effect: z = 0.56, p = 0.58    │
└─────────────────────────────────────────────────┘
```

**Technical approach**:
- R-side calculation (leverage metafor/meta packages?)
- Store in spec, render in footer
- Optional: user provides pre-calculated values
- Careful about assumptions (fixed vs random effects)

**Cost**: MEDIUM
- Statistics are well-defined
- Need to handle missing data gracefully
- Dependency decisions (metafor?)

**Benefit**: HIGH
- Very common need in meta-analysis
- Reduces manual calculation
- Publication-ready output

**Priority**: MEDIUM-HIGH - High value for meta-analysis users

---

### 13. Print/Publication Mode

**Concept**: Optimized rendering for print output with no interactive elements.

**Features**:
- No hover states or tooltips
- Higher default DPI
- Print-optimized colors (avoid pure black)
- Page break hints for long tables
- Optional: grayscale mode

**Technical approach**:
- `publication_mode = TRUE` parameter
- CSS `@media print` rules
- Theme modifier: `set_publication_mode()`
- Affects export defaults

**Cost**: LOW
- Mostly CSS/theme adjustments
- Some conditional rendering

**Benefit**: MEDIUM
- Better print output
- Common request for academic use

**Priority**: MEDIUM - Quick win

---

### 14. In-Place Data Editing

**Concept**: Edit cell values directly in the rendered table.

**Design sketch**:
```
┌─────────────────────────────────────────┐
│ Study          │ OR        │ P-value   │
├─────────────────────────────────────────┤
│ Smith 2020     │ [1.25___] │ 0.032     │  ← click to edit
│                │ ✓ ✗       │           │
```

**Technical approach**:
- Double-click or edit button to enter edit mode
- Validate input type (numeric, text)
- Sync back to R (Shiny) or track changes locally
- Undo/redo support
- Export changes as data frame

**Cost**: HIGH
- Bidirectional data sync
- Input validation
- Undo/redo state management
- Conflict with formula-based columns

**Benefit**: LOW-MEDIUM
- Quick corrections useful
- But: most users prefer code-based changes
- Risk of losing reproducibility

**Priority**: LOW - Conflicts with reproducibility goals

---

### 15. Import from Standard Formats

**Concept**: Read data from common meta-analysis file formats.

**Formats**:
- RevMan 5 (.rm5) - Cochrane Review Manager
- CMA files - Comprehensive Meta-Analysis
- PRISMA checklist integration
- Excel templates with standard structure

**Technical approach**:
- R functions: `read_revman()`, `read_cma()`, etc.
- Map to WebSpec structure
- Handle format variations gracefully
- Vignette with import workflows

**Cost**: MEDIUM
- Format reverse-engineering
- Edge case handling
- Maintenance as formats evolve

**Benefit**: MEDIUM
- Useful for Cochrane/systematic review community
- But: most users have data in R already

**Priority**: LOW-MEDIUM - Niche but valuable for target audience

---

### 16. Funnel Plot Integration

**Concept**: Add funnel plot as companion visualization for publication bias assessment.

**Design sketch**:
```r
forest_plot(data, ...) |>
  add_funnel_plot(position = "right")  # or "below", "panel"
```

**Technical approach**:
- New plot type: funnel (effect size vs SE/precision)
- Linked to main forest plot (shared selection)
- Egger's line, trim-and-fill visualization
- Could be separate widget or integrated panel

**Cost**: MEDIUM
- New SVG rendering
- Layout integration decisions
- Statistical calculations

**Benefit**: MEDIUM-HIGH
- Standard companion to forest plots
- Publication requirement for many journals

**Priority**: MEDIUM - Natural extension of package scope

---

## Priority Matrix

| Direction | Cost | Benefit | Priority | Rationale |
|-----------|------|---------|----------|-----------|
| 7. Enhanced filtering/sorting | M | H | **HIGH** | Core feature, broad impact |
| 10. Accessibility | M | H | **HIGH** | Professional requirement |
| 2. Improved resizing | M | H | **M-HIGH** | UX polish, constant use |
| 8. Linked brushing | M | H | **M-HIGH** | Split forest synergy |
| 12. Statistical annotations | M | H | **M-HIGH** | Meta-analysis core need |
| 5. Embedded subtables | H | H | **MEDIUM** | Unique, but complex |
| 3. Export (PPTX focus) | M | M | **MEDIUM** | Specific high-value format |
| 4. New plot types | H | M-H | **MEDIUM** | Differentiator, high cost |
| 16. Funnel plot | M | M-H | **MEDIUM** | Natural extension |
| 13. Publication mode | L | M | **MEDIUM** | Quick win |
| 9. Animations | L-M | M | **MEDIUM** | Polish |
| 6. Column/row reorder | M | M | **LOW-M** | Column useful, row niche |
| 15. Import formats | M | M | **LOW-M** | Niche audience |
| 1. Interactive styling | H | M | **LOW** | Nice-to-have |
| 11. Plugin system | H | M | **LOW** | Over-engineering risk |
| 14. In-place editing | H | L-M | **LOW** | Conflicts w/ reproducibility |

---

## Recommended Roadmap

### Phase 1: Polish & Professional (Quick Wins)
- Enhanced filtering/sorting UI
- Accessibility audit & fixes
- Publication mode
- Animation/transitions

### Phase 2: Power Features
- Improved resizing UX
- Linked brushing for split forests
- Statistical annotations (I², etc.)
- PPTX export

### Phase 3: Advanced Visualization
- Embedded subtables
- New plot types (boxplot, violin)
- Funnel plot integration

### Phase 4: Ecosystem
- Import from RevMan/CMA
- Custom renderer plugins (if demand exists)

---

## Notes

- Priorities should be validated against user feedback
- Consider GitHub issues/discussions for demand signals
- Balance new features vs stability/documentation
- Some features may warrant separate packages (e.g., `webforest.meta` for statistical annotations)
