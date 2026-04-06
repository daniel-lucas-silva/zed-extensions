---
date: 2026-04-06
topic: "Pine Script Zed Extension — Phase 1 Foundation"
status: validated
---

# Pine Script Zed Extension — Foundation Design

## Problem Statement

The Pine Script extension for Zed was assembled from pieces of multiple projects that don't fit together. The tree-sitter grammar uses `{}` for blocks, but Pine Script uses **indentation** (like Python). The `.scm` query files reference node names that don't exist in the grammar. The `extension.toml` is missing required fields. Everything needs to be rebuilt on a solid foundation.

## Constraints

- **Pine Script is indentation-based** — the grammar MUST use an external scanner with INDENT/DEDENT tokens
- **Zed requires `schema_version = 1`** in extension.toml
- **MIT license** — all borrowed code (revanthpobala grammar) is MIT-licensed ✓
- **Tree-sitter grammar must match .scm files** — node names must be consistent
- **Lua and Gleam extensions** exist as reference patterns (copied from Zed official)
- **No npm/Node.js** — Zed extensions use Cargo/WASM, not Node

## Approach

**Replace the current grammar.js with revanthpobala's grammar** (located at `.ref/revanthpobala_pinescript-vscode-extension/tree-sitter-pinescript/`). This grammar:

- Has `scanner.c` for indentation handling (INDENT/DEDENT/NEWLINE tokens)
- Covers all essential Pine Script constructs (types, methods, imports, switch, for..in, history refs, ternary)
- Uses `block: seq($._indent, repeat1($._statement), $._dedent)` — correct indentation blocks

**Keep the nuniesmith LSP** (in `lsp/`) for Phase 2 — it's a complete Rust LSP with 500+ builtins, parser, linter.

## Architecture

```
extensions/pinescript/
├── extension.toml              # Manifest (schema_version=1, grammars, language_servers)
├── Cargo.toml                  # WASM crate for zed_extension_api
├── LICENSE                     # MIT
├── src/
│   └── pinescript.rs           # Extension entry point (LSP config)
├── tree-sitter/
│   ├── grammar.js              # From revanthpobala (adapted)
│   ├── tree-sitter.json        # Tree-sitter config
│   └── src/
│       ├── scanner.c           # External scanner (indentation)
│       ├── parser.c            # Generated
│       └── parser.h            # Generated
├── languages/pinescript/
│   ├── config.toml             # Language config
│   ├── highlights.scm          # Syntax highlighting (rewritten)
│   ├── indents.scm             # Indentation rules (rewritten)
│   ├── outline.scm             # Sidebar outline (rewritten)
│   ├── folds.scm               # Code folding (rewritten)
│   ├── brackets.scm            # Bracket matching
│   ├── tags.scm                # (empty)
│   ├── textobjects.scm         # (empty)
│   └── injections.scm          # (empty)
├── lsp/                        # Pine LSP (Phase 2)
│   └── ...
├── snippets/
│   └── pinescript.json         # 50+ snippets (Phase 3)
└── indicator-test.ps           # Test file
```

## Components

### 1. extension.toml (Fix)

Add missing `schema_version = 1`, `name = "Pine Script"`. Configure `[grammars.pinescript]` section. Comment out `[language_servers]` until Phase 2.

### 2. Cargo.toml (Fix)

Change `edition = "2026"` → `"2021"`. Keep `zed_extension_api = "0.0.6"`.

### 3. config.toml (Fix)

Align bracket format with Zed's expected schema (use Lua extension as reference). Keep name="PineScript", grammar="pinescript", suffixes=["pine","ps","pinescript"].

### 4. grammar.js (Replace)

Copy from `.ref/revanthpobala_pinescript-vscode-extension/tree-sitter-pinescript/grammar.js`. Adapt `name` field to match `pinescript` id.

### 5. scanner.c (Add)

Copy from `.ref/revanthpobala_pinescript-vscode-extension/tree-sitter-pinescript/src/scanner.c`.

### 6. highlights.scm (Rewrite)

Map node types from the new grammar to Zed highlight captures:

| Grammar Node                       | Highlight Capture      |
| ---------------------------------- | ---------------------- |
| `comment`                          | `@comment`             |
| `string`                           | `@string`              |
| `number`                           | `@number`              |
| `bool_literal`                     | `@constant.builtin`    |
| `type` (int, float, etc.)          | `@type.builtin`        |
| `qualifier` (series, simple, etc.) | `@keyword.modifier`    |
| `function_definition` name         | `@function`            |
| `method_definition` name           | `@function.method`     |
| `type_definition` name             | `@type`                |
| `function_call` function           | `@function.call`       |
| `member_access` member             | `@property`            |
| `variable_declaration` name        | `@variable`            |
| `identifier`                       | `@variable`            |
| Keywords (if, for, var, etc.)      | `@keyword`             |
| Operators (+, -, ==, etc.)         | `@operator`            |
| `version_directive`                | `@attribute`           |
| `import_statement`                 | `@keyword.import`      |
| `history_reference` brackets       | `@punctuation.bracket` |

### 7. indents.scm (Rewrite)

Use `block`, `function_definition`, `method_definition`, `type_definition`, `if_statement`, `for_statement` as indent triggers.

### 8. outline.scm (Rewrite)

Show `function_definition`, `method_definition`, `type_definition`, `variable_declaration` (with var/varip) in sidebar.

### 9. folds.scm (Rewrite)

Fold on `block`, `function_definition`, `method_definition`, `type_definition`, `if_statement`, `for_statement`.

### 10. Files to Remove

- `src/example.rs` — Clojure copy-paste, not needed
- `tree-sitter/src/bindings/node/` — Node.js bindings, Zed doesn't use
- Root `package.json` — npm workspace config, not needed for Zed
- `extensions/pinescript/package.json` — same reason

## Node Types Reference (from revanthpobala grammar)

### Statements

- `version_directive` — `//@version=6`
- `import_statement` — `import lib/module`
- `function_definition` — `myFunc(x) =>`
- `method_definition` — `method myMethod(self) =>`
- `type_definition` — `type MyType`
- `variable_declaration` — `var int x = 10` (with var/varip + optional type)
- `simple_declaration` — `x = 10` (no var keyword)
- `assignment` — `x := 10`
- `compound_assignment` — `x += 10`, `x -= 10`
- `if_statement` — control flow
- `for_statement` — `for..in` and `for..to`
- `switch_statement` — switch blocks
- `while_statement` — while loops
- `continue_statement`, `break_statement`, `return_statement`
- `expression_statement` — bare expression

### Expressions

- `function_call` — `ta.sma(close, 14)`
- `member_access` — `ta.sma`, `strategy.entry`
- `binary_expression` — `+`, `-`, `==`, `and`, `or`, etc.
- `unary_expression` — `not`, `-`
- `conditional_expression` — ternary `a ? b : c`
- `history_reference` — `close[1]`
- `if_expression` — inline if
- `tuple_expression` — `[a, b, c]`
- `parenthesized_expression`

### Literals & Types

- `number`, `string`, `bool_literal`, `color_literal`, `na_literal`
- `type` — int, float, bool, string, color, label, line, linefill, table, box, polyline, chart.point
- `qualifier` — series, simple, const, input
- `identifier`

### Structure

- `block` — `seq($._indent, repeat1($._statement), $._dedent)`
- `comment` — `// ...`

## Error Handling

- If `tree-sitter generate` fails after replacing grammar, check node-types alignment
- If .scm files reference non-existent nodes, tree-sitter will silently ignore them (not crash) — but highlighting won't work
- The scanner.c has a fixed indent stack of 32 levels — sufficient for Pine Script

## Testing Strategy

1. After replacing grammar + scanner.c, run `tree-sitter generate` in the tree-sitter directory
2. Run `tree-sitter parse indicator-test.ps` to verify parsing
3. Install as dev extension in Zed (`Install Dev Extension` → point to `extensions/pinescript/`)
4. Open `indicator-test.ps` and verify syntax highlighting
5. Check outline panel shows function definitions and type definitions

## Open Questions

- **LSP binary distribution**: In Phase 2, should the LSP be compiled as a separate binary that Zed downloads, or bundled via WASM? (The nuniesmith LSP uses tokio + tower-lsp which are heavy for WASM — likely needs to be a separate binary.)
- **Grammar completeness**: The revanthpobala grammar may not cover 100% of Pine Script v6 syntax. Edge cases will be discovered during testing and addressed in Phase 4.
