# Pine Script Zed Extension — Phase 1 Foundation Implementation Plan

**Goal:** Rebuild the Pine Script extension with a working tree-sitter grammar (revanthpobala), proper .scm query files, and Zed-compatible configuration.

**Architecture:** Replace the broken `{}`-based grammar with revanthpobala's indentation-based grammar using external scanner. Rewrite all .scm files to match the new grammar's node types. Fix configuration files to match Zed's schema.

**Design:** [thoughts/shared/designs/2026-04-06-pinescript-foundation-design.md](../designs/2026-04-06-pinescript-foundation-design.md)

---

## Dependency Graph

```
Batch 1 (parallel): 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7 [foundation - no deps]
Batch 2 (parallel): 2.1, 2.2 [grammar files - no deps]
Batch 3 (parallel): 3.1, 3.2, 3.3, 3.4, 3.5 [scm files - depend on grammar nodes]
Batch 4 (parallel): 4.1, 4.2, 4.3 [cleanup and move - no deps]
Batch 5 (sequential): 5.1 [regenerate parser - depends on 2.1, 2.2]
Batch 6 (parallel): 6.1 [test - depends on all previous]
```

---

## Batch 1: Configuration Fixes (parallel - 7 implementers)

All tasks in this batch have NO dependencies and run simultaneously. These fix the broken configuration files.

### Task 1.1: Fix extension.toml

**File:** `extensions/pinescript/extension.toml`
**Test:** none (config file)
**Depends:** none

**Current broken state:** Missing `schema_version`, `name`, and proper `[grammars.pinescript]` section.

```toml
schema_version = 1
id = "pinescript"
name = "Pine Script"
version = "0.1.0"
summary = "Pine Script language support for Zed"
description = "Syntax highlighting, snippets, and LSP support for TradingView's Pine Script (v5/v6)"
authors = ["daniel-lucas-silva"]
repository = "https://github.com/daniel-lucas-silva/zed-extensions"
license = "MIT"

[grammars.pinescript]
path = "tree-sitter"

# Phase 2: Uncomment when LSP is ready
# [language_servers.pine-lsp]
# name = "Pine LSP"
# language = "Pine Script"
```

**Verify:** File syntax is valid TOML
**Commit:** `fix(pinescript): add schema_version and grammar configuration to extension.toml`

---

### Task 1.2: Fix Cargo.toml

**File:** `extensions/pinescript/Cargo.toml`
**Test:** none (config file)
**Depends:** none

**Current broken state:** `edition = "2026"` is invalid (should be "2021").

```toml
[package]
name = "zed_pinescript"
version = "0.1.0"
edition = "2021"
publish = false
license = "MIT"

[lints]
workspace = true

[lib]
path = "src/pinescript.rs"
crate-type = ["cdylib"]

[dependencies]
zed_extension_api = "0.0.6"
```

**Verify:** `cargo check` passes (or at least doesn't error on edition)
**Commit:** `fix(pinescript): correct edition to 2021 in Cargo.toml`

---

### Task 1.3: Fix config.toml

**File:** `extensions/pinescript/languages/pinescript/config.toml`
**Test:** none (config file)
**Depends:** none

**Current broken state:** Uses wrong bracket format (Zed uses array format, not [brackets] section).

**Reference:** `extensions/lua/languages/lua/config.toml` uses:

```toml
brackets = [
    { start = "{", end = "}", close = true, newline = true },
    ...
]
```

**New content:**

```toml
name = "Pine Script"
grammar = "pinescript"
path_suffixes = ["pine", "ps", "pinescript"]
line_comments = ["// "]
autoclose_before = ";:.,=}])>"
brackets = [
    { start = "(", end = ")", close = true, newline = false },
    { start = "[", end = "]", close = true, newline = false },
    { start = "'", end = "'", close = true, newline = false, not_in = ["string", "comment"] },
    { start = "\"", end = "\"", close = true, newline = false, not_in = ["string", "comment"] },
]
tab_size = 4
hard_tabs = false
```

**Note:** Pine Script doesn't use `{}` for blocks (it uses indentation), so we don't include curly braces in brackets.

**Verify:** File syntax is valid TOML
**Commit:** `fix(pinescript): align config.toml with Zed schema`

---

### Task 1.4: Update tree-sitter.json

**File:** `extensions/pinescript/tree-sitter/tree-sitter.json`
**Test:** none (config file)
**Depends:** none

**Current state:** Has extra metadata that may cause issues. Simplify to standard format.

```json
{
  "name": "pinescript",
  "version": "0.1.0",
  "description": "Tree-sitter grammar for Pine Script",
  "author": "Revanth Pobala (adapted)",
  "license": "MIT",
  "keywords": ["tree-sitter", "parser", "pinescript", "pine-script"],
  "repository": {
    "type": "git",
    "url": "https://github.com/daniel-lucas-silva/zed-extensions"
  },
  "grammars": [
    {
      "name": "pinescript",
      "file-types": ["pine", "ps", "pinescript"],
      "scope": "source.pinescript",
      "highlights-query": "../languages/pinescript/highlights.scm",
      "indents-query": "../languages/pinescript/indents.scm",
      "outline-query": "../languages/pinescript/outline.scm",
      "folds-query": "../languages/pinescript/folds.scm",
      "brackets-query": "../languages/pinescript/brackets.scm"
    }
  ]
}
```

**Verify:** Valid JSON
**Commit:** `fix(pinescript): update tree-sitter.json with correct paths`

---

### Task 1.5: Keep pinescript.rs

**File:** `extensions/pinescript/src/pinescript.rs`
**Test:** none (kept as-is for Phase 2)
**Depends:** none

**Action:** Keep the existing file unchanged. It's for Phase 2 LSP integration.

**Current content (verify it's there):**

```rust
use zed_extension_api::{self as zed, LanguageServerId, Result};

struct PineScriptExtension;

impl zed::Extension for PineScriptExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        _server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        worktree
            .which("pine-lsp")
            .map(|path| zed::Command {
                command: path,
                args: vec![],
                env: Default::default(),
            })
            .ok_or_else(|| {
                "pine-lsp not found on PATH.\n\n\
                 Install it with:\n\
                 \n\
                 cargo install --git https://github.com/nuniesmith/pine-script-zed pine-lsp\n\
                 \n\
                 Then reload Zed."
                    .into()
            })
    }
}

zed::register_extension!(PineScriptExtension);
```

**Verify:** File exists and compiles
**Commit:** `chore(pinescript): keep pinescript.rs for LSP Phase 2`

---

### Task 1.6: Create LICENSE file

**File:** `extensions/pinescript/LICENSE`
**Test:** none
**Depends:** none

**Action:** Create MIT license file (required by Zed extension schema).

```
MIT License

Copyright (c) 2026 Daniel Lucas Silva

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

Tree-sitter grammar derived from revanthpobala/pinescript-vscode-extension
Copyright (c) 2024 Revanth Pobala - MIT License
```

**Verify:** File exists
**Commit:** `chore(pinescript): add MIT LICENSE file`

---

### Task 1.7: Verify indicator-test.ps exists

**File:** `extensions/pinescript/indicator-test.ps`
**Test:** none
**Depends:** none

**Action:** Verify the test file exists with valid Pine Script content.

**Expected content:**

```pinescript
//@version=6
indicator("My Custom Indicator", overlay=true)

// Input variables
length = input.int(14, "RSI Length")
overbought = input.float(70, "Overbought Level")
oversold = input.float(30, "Oversold Level")

// Calculate RSI
rsiValue = ta.rsi(close, length)

// Plot RSI
plot(rsiValue, "RSI", color=color.blue)

// Plot overbought/oversold levels
hline(overbought, "Overbought", color=color.red)
hline(oversold, "Oversold", color=color.green)

// Generate trading signals
longCondition = ta.crossover(rsiValue, oversold)
shortCondition = ta.crossunder(rsiValue, overbought)

// Plot signals
plotshape(longCondition, "Buy Signal", location=location.belowbar, color=color.green, style=shape.triangleup, size=size.small)
plotshape(shortCondition, "Sell Signal", location=location.abovebar, color=color.red, style=shape.triangledown, size=size.small)

// Strategy components
if (longCondition)
    strategy.entry("Long", strategy.long)

if (shortCondition)
    strategy.entry("Short", strategy.short)

// Variables and calculations
var float myVar = 0.0
myVar := close > open ? 1.0 : 0.0

// Custom function example
getSMA(src, len) =>
    ta.sma(src, len)

// Using the custom function
sma20 = getSMA(close, 20)
plot(sma20, "20 SMA", color=color.purple)

// Alert conditions
alertcondition(longCondition, "Buy Alert", "RSI crossed above oversold")
alertcondition(shortCondition, "Sell Alert", "RSI crossed below overbought")
```

**Verify:** File exists with valid Pine Script syntax
**Commit:** `chore(pinescript): verify test file indicator-test.ps`

---

## Batch 2: Grammar Files (parallel - 2 implementers)

These tasks replace the broken grammar with the working revanthpobala grammar.

### Task 2.1: Replace grammar.js

**File:** `extensions/pinescript/tree-sitter/grammar.js`
**Test:** none (will be tested in Batch 5)
**Depends:** none

**Action:** Replace the entire file with revanthpobala's grammar (adapted for Zed).

```javascript
module.exports = grammar({
  name: "pinescript",

  // Extras are tokens that can appear anywhere (whitespace, comments)
  extras: ($) => [$.comment, /[ \t\uFEFF\u2060\u200B\u00A0]/],

  // External tokens handled by scanner.c (for indentation)
  // Must match enum in scanner.c: NEWLINE, INDENT, DEDENT
  externals: ($) => [$._newline, $._indent, $._dedent],

  word: ($) => $._identifier,

  conflicts: ($) => [
    [$.conditional_expression, $._expression],
    [$.binary_expression, $.conditional_expression],
    [$.parameter_list, $._expression],
    [$.parameter, $._expression],
    [$.parameter, $.argument],
    [$.return_statement, $._expression],
    [$.function_definition, $.function_call, $._expression],
    [$.type, $.identifier],
    [$.type, $._expression],
    [$.simple_declaration, $.binary_expression],
    [$.tuple_declaration, $._expression],
    [$.history_reference, $._expression],
    [$.if_expression, $.binary_expression],
    [$.if_expression],
    [$._statement, $._statement],
  ],

  rules: {
    source_file: ($) => repeat($._statement),

    _statement: ($) =>
      choice(
        $.version_directive,
        $.import_statement,
        $.variable_declaration,
        $.simple_declaration,
        $.function_definition,
        $.method_definition,
        $.type_definition,
        $.assignment,
        $.compound_assignment,
        $.if_statement,
        $.for_statement,
        $.continue_statement,
        $.break_statement,
        $.return_statement,
        $.expression_statement,
        $._newline,
        prec.left(1, seq($._statement, ",", $._statement)), // Support multiple statements on one line (commas)
      ),

    comment: ($) => token(seq("//", /.*/)),

    version_directive: ($) => seq("//@version=", /\d+/),

    import_statement: ($) =>
      seq(
        "import",
        field("library", $.library_path),
        optional(seq("as", field("alias", $.identifier))),
      ),

    library_path: ($) => /[a-zA-Z0-9_]+\/[a-zA-Z0-9_]+\/\d+/,

    // Example: "var int x = 10" or "x = 10" or "[x, y] = request.security(...)"
    // Example: "var int x = 10" or "int x = 10"
    variable_declaration: ($) =>
      prec.dynamic(
        5,
        seq(
          choice(seq(choice("var", "varip"), optional($.type)), $.type),
          field(
            "name",
            choice(
              $.identifier,
              $.tuple_declaration,
              $.member_access,
              $.function_call,
            ),
          ),
          "=",
          field("value", $._expression),
        ),
      ),

    // Example: "x = 10"
    simple_declaration: ($) =>
      prec(
        1,
        seq(
          field(
            "name",
            choice(
              $.identifier,
              $.tuple_declaration,
              $.member_access,
              $.function_call,
            ),
          ),
          "=",
          field("value", $._expression),
        ),
      ),

    // Example: "myFunc(float x, y) => x + y"
    function_definition: ($) =>
      seq(
        optional("export"),
        field("name", $.identifier),
        "(",
        optional(field("parameters", $.parameter_list)),
        ")",
        "=>",
        field("body", choice($._expression, $.block)),
      ),

    method_definition: ($) =>
      seq(
        optional("export"),
        "method",
        field("name", $.identifier),
        "(",
        optional(field("parameters", $.parameter_list)),
        ")",
        "=>",
        field("body", choice($._expression, $.block)),
      ),

    type_definition: ($) => seq("type", field("name", $.identifier), $.block),

    parameter_list: ($) => seq($.parameter, repeat(seq(",", $.parameter))),

    parameter: ($) =>
      seq(
        optional($.qualifier),
        optional($.type),
        $.identifier,
        optional(seq("=", $._expression)),
      ),

    qualifier: ($) => choice("series", "simple", "const", "input"),

    tuple_declaration: ($) =>
      seq(
        "[",
        seq(optional($.type), $.identifier),
        repeat(seq(",", seq(optional($.type), $.identifier))),
        "]",
      ),

    assignment: ($) =>
      seq(
        field(
          "name",
          choice(
            $.identifier,
            $.tuple_declaration,
            $.member_access,
            $.function_call,
          ),
        ),
        ":=",
        field("value", $._expression),
      ),

    compound_assignment: ($) =>
      seq(
        field("name", $.identifier),
        choice("+=", "-=", "*=", "/=", "%="),
        field("value", $._expression),
      ),

    function_call: ($) =>
      prec(
        2,
        seq(
          field("function", choice($.identifier, $.member_access)),
          "(",
          optional($.argument_list),
          ")",
        ),
      ),

    member_access: ($) =>
      prec(
        5,
        seq(field("object", $._expression), ".", field("member", $.identifier)),
      ),

    argument_list: ($) => seq($.argument, repeat(seq(",", $.argument))),

    argument: ($) =>
      choice(
        $._expression,
        prec(
          3,
          seq(field("name", $.identifier), "=", field("value", $._expression)),
        ),
      ),

    // Control Structures rely on Indent/Dedent from scanner.c
    if_statement: ($) =>
      seq(
        "if",
        field("condition", $._expression),
        optional(":"), // Make colon optional
        $.block,
      ),

    for_statement: ($) =>
      choice(
        // for i in array
        seq(
          "for",
          field("variable", $.identifier),
          "in",
          $._expression,
          $.block,
        ),
        // for i = 0 to 10
        seq(
          "for",
          field("variable", $.identifier),
          "=",
          field("start", $._expression),
          "to",
          field("end", $._expression),
          optional(seq("by", field("step", $._expression))),
          $.block,
        ),
      ),

    continue_statement: ($) => "continue",
    break_statement: ($) => "break",

    return_statement: ($) =>
      choice(prec(2, seq("return", $._expression)), prec(1, "return")),

    expression_statement: ($) => prec(10, $._expression),

    block: ($) => seq($._indent, repeat1($._statement), $._dedent),

    _expression: ($) =>
      choice(
        $.identifier,
        $.number,
        $.string,
        $.bool_literal,
        $.member_access,
        $.tuple_expression,
        prec(1, $.function_call),
        $.binary_expression,
        $.conditional_expression,
        $.unary_expression,
        $.history_reference,
        $.if_expression,
        seq("(", $._expression, ")"),
      ),

    tuple_expression: ($) =>
      seq("[", $._expression, repeat(seq(",", $._expression)), "]"),

    bool_literal: ($) => choice("true", "false"),

    unary_expression: ($) =>
      prec(3, seq(choice("not", "-", "+"), $._expression)),

    history_reference: ($) =>
      prec(4, seq($._expression, "[", $._expression, "]")),

    conditional_expression: ($) =>
      prec.right(
        0,
        seq(
          field("condition", $._expression),
          "?",
          field("consequence", $._expression),
          ":",
          field("alternative", $._expression),
        ),
      ),

    if_expression: ($) =>
      prec.right(
        1,
        seq(
          "if",
          field("condition", $._expression),
          field("then", choice($._expression, $.block)),
          optional(seq("else", field("else", choice($._expression, $.block)))),
        ),
      ),

    binary_expression: ($) =>
      choice(
        prec.left(2, seq($._expression, choice("*", "/", "%"), $._expression)),
        prec.left(1, seq($._expression, choice("+", "-"), $._expression)),
        prec.left(
          0,
          seq(
            $._expression,
            choice(">", "<", ">=", "<=", "==", "!="),
            $._expression,
          ),
        ),
        prec.left(-1, seq($._expression, choice("and", "or"), $._expression)),
      ),

    type: ($) =>
      seq(
        choice(
          "int",
          "float",
          "bool",
          "string",
          "color",
          "label",
          "line",
          "linefill",
          "table",
          "box",
          "polyline",
          "chart.point",
        ),
        optional("[]"),
      ),

    identifier: ($) =>
      choice(
        choice(
          "int",
          "float",
          "bool",
          "string",
          "color",
          "label",
          "line",
          "table",
          "box",
        ),
        $._identifier,
      ),

    _identifier: ($) => /[a-zA-Z_][a-zA-Z0-9_]*/,

    number: ($) => /\d+(\.\d+)?/,

    string: ($) => choice(seq("'", /[^']*/, "'"), seq('"', /[^"]*/, '"')),
  },
});

function sep1(rule, separator) {
  return seq(rule, repeat(seq(separator, rule)));
}
```

**Verify:** Valid JavaScript syntax
**Commit:** `feat(pinescript): replace grammar.js with revanthpobala indentation-based grammar`

---

### Task 2.2: Add scanner.c

**File:** `extensions/pinescript/tree-sitter/src/scanner.c`
**Test:** none (will be tested in Batch 5)
**Depends:** none

**Action:** Create the external scanner for indentation handling.

```c
#include "tree_sitter/parser.h"
#include <stdint.h>
#include <stdlib.h>

// External tokens - must match grammar.js externals order
enum TokenType {
  NEWLINE,
  INDENT,
  DEDENT,
};

#define STACK_SIZE 32

typedef struct {
  uint16_t stack[STACK_SIZE];
  uint8_t stack_depth;
} Scanner;

void *tree_sitter_pinescript_external_scanner_create() {
  Scanner *scanner = (Scanner *)calloc(1, sizeof(Scanner));
  if (scanner) {
    scanner->stack[0] = 0;
    scanner->stack_depth = 1;
  }
  return scanner;
}

void tree_sitter_pinescript_external_scanner_destroy(void *payload) {
  free(payload);
}

unsigned tree_sitter_pinescript_external_scanner_serialize(void *payload,
                                                           char *buffer) {
  Scanner *scanner = (Scanner *)payload;
  unsigned size = 0;
  buffer[size++] = (char)scanner->stack_depth;
  for (uint8_t i = 0; i < scanner->stack_depth &&
                      size + 1 < TREE_SITTER_SERIALIZATION_BUFFER_SIZE;
       i++) {
    buffer[size++] = (char)(scanner->stack[i] & 0xFF);
    buffer[size++] = (char)((scanner->stack[i] >> 8) & 0xFF);
  }
  return size;
}

void tree_sitter_pinescript_external_scanner_deserialize(void *payload,
                                                         const char *buffer,
                                                         unsigned length) {
  Scanner *scanner = (Scanner *)payload;
  scanner->stack_depth = 1;
  scanner->stack[0] = 0;
  if (length > 0) {
    scanner->stack_depth = (uint8_t)buffer[0];
    if (scanner->stack_depth > STACK_SIZE)
      scanner->stack_depth = STACK_SIZE;
    unsigned size = 1;
    for (uint8_t i = 0; i < scanner->stack_depth && size + 1 < length; i++) {
      scanner->stack[i] = (uint16_t)((uint8_t)buffer[size] |
                                     (((uint8_t)buffer[size + 1]) << 8));
      size += 2;
    }
  }
}

static void skip(TSLexer *lexer) { lexer->advance(lexer, true); }

bool tree_sitter_pinescript_external_scanner_scan(void *payload, TSLexer *lexer,
                                                  const bool *valid_symbols) {
  Scanner *scanner = (Scanner *)payload;

  // 1. Check for EOF and Dedent everything
  if (lexer->eof(lexer)) {
    if (scanner->stack_depth > 1 && valid_symbols[DEDENT]) {
      scanner->stack_depth--;
      lexer->result_symbol = DEDENT;
      return true;
    }
    return false;
  }

  // 2. Scan leading whitespace/newlines
  bool has_newline = false;
  uint16_t indent_column = 0;

  while (lexer->lookahead == ' ' || lexer->lookahead == '\t' ||
         lexer->lookahead == '\r' || lexer->lookahead == '\n') {
    if (lexer->lookahead == '\n') {
      has_newline = true;
      indent_column = 0;
    } else if (lexer->lookahead == ' ') {
      indent_column++;
    } else if (lexer->lookahead == '\t') {
      indent_column += 4;
    }
    skip(lexer);
  }

  // 3. Emit tokens based on indentation change
  if (has_newline) {
    uint16_t current_indent = scanner->stack[scanner->stack_depth - 1];

    if (indent_column > current_indent && valid_symbols[INDENT]) {
      if (scanner->stack_depth < STACK_SIZE) {
        scanner->stack[scanner->stack_depth++] = indent_column;
        lexer->result_symbol = INDENT;
        return true;
      }
    } else if (indent_column < current_indent && valid_symbols[DEDENT]) {
      scanner->stack_depth--;
      lexer->result_symbol = DEDENT;
      return true;
    } else if (valid_symbols[NEWLINE]) {
      lexer->result_symbol = NEWLINE;
      return true;
    }
  }

  return false;
}
```

**Verify:** Valid C syntax
**Commit:** `feat(pinescript): add external scanner.c for indentation handling`

---

## Batch 3: SCM Query Files (parallel - 5 implementers)

These tasks rewrite all .scm files to match the new grammar's node types. Each file is independent.

### Task 3.1: Rewrite highlights.scm

**File:** `extensions/pinescript/languages/pinescript/highlights.scm`
**Test:** `cd extensions/pinescript/tree-sitter && tree-sitter query ../languages/pinescript/highlights.scm indicator-test.ps` (after parser generation)
**Depends:** none (but grammar must exist for testing)

**Action:** COMPLETELY rewrite highlights.scm to map all grammar nodes to Zed highlight captures.

**Node type reference from grammar.js:**

- Statements: version_directive, import_statement, function_definition, method_definition, type_definition, variable_declaration, simple_declaration, assignment, compound_assignment, if_statement, for_statement, continue_statement, break_statement, return_statement, expression_statement
- Expressions: function_call, member_access, binary_expression, unary_expression, conditional_expression, history_reference, if_expression, tuple_expression
- Literals: number, string, bool_literal
- Types: type (int, float, bool, string, color, label, line, linefill, table, box, polyline, chart.point)
- Qualifiers: qualifier (series, simple, const, input)
- Structure: block, comment

```scheme
; =============================================================================
; Pine Script Syntax Highlighting for Zed
; Grammar: revanthpobala/tree-sitter-pinescript (indentation-based)
; =============================================================================

; -----------------------------------------------------------------------------
; Comments
; -----------------------------------------------------------------------------
(comment) @comment

; -----------------------------------------------------------------------------
; Version Directive
; -----------------------------------------------------------------------------
(version_directive) @attribute

; -----------------------------------------------------------------------------
; Import Statements
; -----------------------------------------------------------------------------
(import_statement
  "import" @keyword.import)

(import_statement
  library: (library_path) @string.special.path)

(import_statement
  "as" @keyword.import)

; -----------------------------------------------------------------------------
; Type Definitions
; -----------------------------------------------------------------------------
(type_definition
  "type" @keyword.type)

(type_definition
  name: (identifier) @type)

; -----------------------------------------------------------------------------
; Function Definitions
; -----------------------------------------------------------------------------
(function_definition
  "export"? @keyword.modifier)

(function_definition
  name: (identifier) @function)

(function_definition
  "=>" @punctuation.special)

; -----------------------------------------------------------------------------
; Method Definitions
; -----------------------------------------------------------------------------
(method_definition
  "export"? @keyword.modifier)

(method_definition
  "method" @keyword.function)

(method_definition
  name: (identifier) @function.method)

(method_definition
  "=>" @punctuation.special)

; -----------------------------------------------------------------------------
; Variable Declarations
; -----------------------------------------------------------------------------
(variable_declaration
  "var" @keyword.storage)

(variable_declaration
  "varip" @keyword.storage)

(variable_declaration
  type: (type) @type.builtin)

(variable_declaration
  name: (identifier) @variable)

(variable_declaration
  name: (tuple_declaration) @variable)

(variable_declaration
  "=" @operator)

; -----------------------------------------------------------------------------
; Simple Declarations (x = 10)
; -----------------------------------------------------------------------------
(simple_declaration
  name: (identifier) @variable)

(simple_declaration
  name: (tuple_declaration) @variable)

(simple_declaration
  "=" @operator)

; -----------------------------------------------------------------------------
; Assignments (x := 10)
; -----------------------------------------------------------------------------
(assignment
  name: (identifier) @variable)

(assignment
  name: (tuple_declaration) @variable)

(assignment
  name: (member_access) @property)

(assignment
  ":=" @operator)

; -----------------------------------------------------------------------------
; Compound Assignments (+=, -=, etc.)
; -----------------------------------------------------------------------------
(compound_assignment
  name: (identifier) @variable)

(compound_assignment
  ["+=" "-=" "*=" "/=" "%="] @operator)

; -----------------------------------------------------------------------------
; Control Flow - If Statements
; -----------------------------------------------------------------------------
(if_statement
  "if" @keyword.conditional)

(if_statement
  condition: (identifier) @variable)

(if_statement
  condition: (member_access) @property)

(if_statement
  condition: (function_call) @function.call)

; -----------------------------------------------------------------------------
; Control Flow - For Statements
; -----------------------------------------------------------------------------
(for_statement
  "for" @keyword.repeat)

(for_statement
  "in" @keyword.repeat)

(for_statement
  "to" @keyword.repeat)

(for_statement
  "by" @keyword.repeat)

(for_statement
  variable: (identifier) @variable)

; -----------------------------------------------------------------------------
; Control Flow - Break/Continue/Return
; -----------------------------------------------------------------------------
(continue_statement) @keyword.repeat

(break_statement) @keyword.repeat

(return_statement
  "return" @keyword.return)

; -----------------------------------------------------------------------------
; Function Calls
; -----------------------------------------------------------------------------
(function_call
  function: (identifier) @function.call)

(function_call
  function: (member_access
    member: (identifier) @function.call))

; -----------------------------------------------------------------------------
; Member Access (ta.sma, strategy.entry)
; -----------------------------------------------------------------------------
(member_access
  object: (identifier) @variable)

(member_access
  object: (member_access) @property)

(member_access
  "." @punctuation.delimiter)

(member_access
  member: (identifier) @property)

; -----------------------------------------------------------------------------
; Binary Expressions
; -----------------------------------------------------------------------------
(binary_expression
  ["+" "-" "*" "/" "%"] @operator)

(binary_expression
  [">" "<" ">=" "<=" "==" "!="] @operator)

(binary_expression
  ["and" "or"] @keyword.operator)

; -----------------------------------------------------------------------------
; Unary Expressions
; -----------------------------------------------------------------------------
(unary_expression
  ["not" "-" "+"] @operator)

; -----------------------------------------------------------------------------
; Conditional/Ternary Expressions
; -----------------------------------------------------------------------------
(conditional_expression
  "?" @punctuation.special)

(conditional_expression
  ":" @punctuation.special)

; -----------------------------------------------------------------------------
; If Expressions (inline if)
; -----------------------------------------------------------------------------
(if_expression
  "if" @keyword.conditional)

(if_expression
  "else" @keyword.conditional)

; -----------------------------------------------------------------------------
; History References (close[1])
; -----------------------------------------------------------------------------
(history_reference
  "[" @punctuation.bracket)

(history_reference
  "]" @punctuation.bracket)

; -----------------------------------------------------------------------------
; Literals
; -----------------------------------------------------------------------------
(number) @number

(string) @string

(bool_literal) @constant.builtin.boolean

; -----------------------------------------------------------------------------
; Types (built-in)
; -----------------------------------------------------------------------------
(type) @type.builtin

; -----------------------------------------------------------------------------
; Qualifiers (series, simple, const, input)
; -----------------------------------------------------------------------------
(qualifier) @keyword.modifier

; -----------------------------------------------------------------------------
; Identifiers
; -----------------------------------------------------------------------------
(identifier) @variable

; -----------------------------------------------------------------------------
; Parameters
; -----------------------------------------------------------------------------
(parameter
  type: (type) @type.builtin)

(parameter
  (identifier) @variable.parameter)

; -----------------------------------------------------------------------------
; Tuple Declarations
; -----------------------------------------------------------------------------
(tuple_declaration
  "[" @punctuation.bracket)

(tuple_declaration
  "]" @punctuation.bracket)

; -----------------------------------------------------------------------------
; Tuple Expressions
; -----------------------------------------------------------------------------
(tuple_expression
  "[" @punctuation.bracket)

(tuple_expression
  "]" @punctuation.bracket)

; -----------------------------------------------------------------------------
; Punctuation - Brackets
; -----------------------------------------------------------------------------
["(" ")"] @punctuation.bracket

; -----------------------------------------------------------------------------
; Punctuation - Delimiters
; -----------------------------------------------------------------------------
"," @punctuation.delimiter

; -----------------------------------------------------------------------------
; Named Arguments
; -----------------------------------------------------------------------------
(argument
  name: (identifier) @property)

(argument
  "=" @operator)
```

**Verify:** Query parses without errors after parser generation
**Commit:** `feat(pinescript): rewrite highlights.scm for new grammar`

---

### Task 3.2: Rewrite indents.scm

**File:** `extensions/pinescript/languages/pinescript/indents.scm`
**Test:** `tree-sitter query` test (after parser generation)
**Depends:** none

**Action:** Rewrite for indentation-based grammar using block node.

```scheme
; =============================================================================
; Pine Script Indentation Rules
; =============================================================================

; Indent after entering a block
(block) @indent

; Indent after function/method definitions
(function_definition) @indent
(method_definition) @indent
(type_definition) @indent

; Indent after control flow statements
(if_statement) @indent
(for_statement) @indent

; Align when dedenting
(_ "}" @end) @aligned
```

**Verify:** Query parses without errors
**Commit:** `feat(pinescript): rewrite indents.scm for indentation-based grammar`

---

### Task 3.3: Rewrite outline.scm

**File:** `extensions/pinescript/languages/pinescript/outline.scm`
**Test:** `tree-sitter query` test (after parser generation)
**Depends:** none

**Action:** Rewrite to show functions, methods, types, and variables in sidebar.

```scheme
; =============================================================================
; Pine Script Outline (Document Symbol) Queries
; =============================================================================

; Function definitions
(function_definition
  name: (identifier) @name) @item

; Method definitions
(method_definition
  name: (identifier) @name) @item

; Type definitions
(type_definition
  name: (identifier) @name) @item

; Variable declarations with var/varip
(variable_declaration
  "var"
  name: (identifier) @name) @item

(variable_declaration
  "varip"
  name: (identifier) @name) @item

; Simple declarations (top-level variables)
(simple_declaration
  name: (identifier) @name) @item
```

**Verify:** Query parses without errors
**Commit:** `feat(pinescript): rewrite outline.scm for new grammar`

---

### Task 3.4: Rewrite folds.scm

**File:** `extensions/pinescript/languages/pinescript/folds.scm`
**Test:** `tree-sitter query` test (after parser generation)
**Depends:** none

**Action:** Rewrite to fold blocks, functions, and control structures.

```scheme
; =============================================================================
; Pine Script Code Folding
; =============================================================================

; Fold blocks (the main indentation-based blocks)
(block) @fold

; Fold function/method/type definitions
(function_definition) @fold
(method_definition) @fold
(type_definition) @fold

; Fold control flow statements
(if_statement) @fold
(for_statement) @fold

; Fold comments (optional, for large comment blocks)
(comment) @fold
```

**Verify:** Query parses without errors
**Commit:** `feat(pinescript): rewrite folds.scm for new grammar`

---

### Task 3.5: Rewrite brackets.scm

**File:** `extensions/pinescript/languages/pinescript/brackets.scm`
**Test:** `tree-sitter query` test (after parser generation)
**Depends:** none

**Action:** Rewrite for Pine Script brackets (parentheses and square brackets only - no curly braces).

```scheme
; =============================================================================
; Pine Script Bracket Matching
; =============================================================================

; Parentheses for function calls and grouping
("(" @open ")" @close)

; Square brackets for history references and arrays/tuples
("[" @open "]" @close)
```

**Note:** Pine Script doesn't use `{}` for blocks (uses indentation), so we don't include them.

**Verify:** Query parses without errors
**Commit:** `feat(pinescript): rewrite brackets.scm for Pine Script syntax`

---

## Batch 4: Cleanup and File Organization (parallel - 3 implementers)

### Task 4.1: Remove src/example.rs

**File:** `extensions/pinescript/src/example.rs` (DELETE)
**Test:** none
**Depends:** none

**Action:** Delete this file - it's a Clojure copy-paste, not needed.

**Verify:** File no longer exists
**Commit:** `chore(pinescript): remove unused example.rs`

---

### Task 4.2: Remove Node.js bindings

**File:** `extensions/pinescript/tree-sitter/src/bindings/node/` (DELETE DIRECTORY)
**Test:** none
**Depends:** none

**Action:** Delete the entire `node/` directory - Zed doesn't use Node.js bindings.

**Files to delete:**

- `extensions/pinescript/tree-sitter/src/bindings/node/binding.gyp`
- `extensions/pinescript/tree-sitter/src/bindings/node/binding.cc`
- `extensions/pinescript/tree-sitter/src/bindings/node/index.js`

**Verify:** Directory no longer exists
**Commit:** `chore(pinescript): remove Node.js bindings (Zed uses WASM)`

---

### Task 4.3: Move snippets file

**File:** `snippets/pinescript.json` → `extensions/pinescript/snippets/pinescript.json`
**Test:** none
**Depends:** none

**Action:** Move snippets from root to extension directory.

**Source:** `snippets/pinescript.json`
**Destination:** `extensions/pinescript/snippets/pinescript.json`

**Verify:** File exists at new location, not at old location
**Commit:** `chore(pinescript): move snippets to extension directory`

---

## Batch 5: Parser Generation (sequential - 1 implementer)

This task MUST run after Batch 2 (grammar files are in place).

### Task 5.1: Regenerate parser

**File:** `extensions/pinescript/tree-sitter/src/parser.c` and `parser.h` (GENERATED)
**Test:** `tree-sitter parse indicator-test.ps`
**Depends:** 2.1, 2.2 (grammar.js and scanner.c must exist)

**Action:** Run tree-sitter generate to create parser.c and parser.h.

**Prerequisites:**

- tree-sitter CLI must be installed: `cargo install tree-sitter-cli` or `npm install -g tree-sitter-cli`

**Commands:**

```bash
cd extensions/pinescript/tree-sitter
tree-sitter generate
```

**Expected output:**

- `src/parser.c` (generated, ~10k+ lines)
- `src/parser.h` (generated)
- `src/node-types.json` (generated)
- `src/grammar.json` (generated)

**Verify:**

```bash
tree-sitter parse ../indicator-test.ps
```

Should output the AST without ERROR nodes.

**Commit:** `feat(pinescript): regenerate parser from new grammar`

---

## Batch 6: Testing (parallel - 1 implementer)

### Task 6.1: Test in Zed

**File:** N/A (integration test)
**Test:** Manual test in Zed
**Depends:** ALL previous batches (1.1-5.1)

**Action:** Install as dev extension and verify functionality.

**Steps:**

1. Open Zed
2. Run `Install Dev Extension` command
3. Point to `extensions/pinescript/`
4. Open `indicator-test.ps`
5. Verify:
   - Syntax highlighting works (colors on keywords, strings, numbers)
   - Outline panel shows functions and variables
   - Code folding works on indented blocks
   - Bracket matching works for `()` and `[]`
   - Comments are highlighted
   - No ERROR nodes in tree-sitter output

**Commands to verify:**

```bash
cd extensions/pinescript/tree-sitter

# Parse test file
tree-sitter parse ../indicator-test.ps

# Test highlights query
tree-sitter query ../languages/pinescript/highlights.scm ../indicator-test.ps

# Test outline query
tree-sitter query ../languages/pinescript/outline.scm ../indicator-test.ps
```

**Verify:** All tests pass, no ERROR nodes in parse output
**Commit:** `test(pinescript): verify extension works in Zed`

---

## Summary of Changes

### Files Modified:

1. `extension.toml` - Add schema_version, name, grammar config
2. `Cargo.toml` - Fix edition to 2021
3. `languages/pinescript/config.toml` - Align with Zed schema
4. `tree-sitter/tree-sitter.json` - Update paths
5. `tree-sitter/grammar.js` - Replace with revanthpobala grammar
6. `languages/pinescript/highlights.scm` - Rewrite for new grammar
7. `languages/pinescript/indents.scm` - Rewrite for indentation
8. `languages/pinescript/outline.scm` - Rewrite for new grammar
9. `languages/pinescript/folds.scm` - Rewrite for new grammar
10. `languages/pinescript/brackets.scm` - Rewrite for Pine Script

### Files Created:

1. `tree-sitter/src/scanner.c` - External scanner for indentation
2. `LICENSE` - MIT license
3. `tree-sitter/src/parser.c` - Generated (Batch 5)
4. `tree-sitter/src/parser.h` - Generated (Batch 5)

### Files Deleted:

1. `src/example.rs` - Clojure copy-paste
2. `tree-sitter/src/bindings/node/` - Node.js bindings directory

### Files Moved:

1. `snippets/pinescript.json` → `extensions/pinescript/snippets/pinescript.json`

### Files Kept (Phase 2):

1. `src/pinescript.rs` - LSP integration
2. `lsp/` - Complete LSP implementation

---

## Node Types Quick Reference

From the revanthpobala grammar.js:

**Statements:**

- `version_directive` - `//@version=6`
- `import_statement` - `import lib/module`
- `variable_declaration` - `var int x = 10`
- `simple_declaration` - `x = 10`
- `function_definition` - `myFunc(x) =>`
- `method_definition` - `method myMethod(self) =>`
- `type_definition` - `type MyType`
- `assignment` - `x := 10`
- `compound_assignment` - `x += 10`
- `if_statement` - `if condition`
- `for_statement` - `for i in array` or `for i = 0 to 10`
- `continue_statement`, `break_statement`, `return_statement`

**Expressions:**

- `function_call` - `ta.sma(close, 14)`
- `member_access` - `ta.sma`, `strategy.entry`
- `binary_expression` - `+`, `-`, `==`, `and`, `or`
- `unary_expression` - `not`, `-`
- `conditional_expression` - `a ? b : c`
- `history_reference` - `close[1]`
- `if_expression` - inline if
- `tuple_expression` - `[a, b, c]`

**Literals & Types:**

- `number`, `string`, `bool_literal`
- `type` - int, float, bool, string, color, label, line, linefill, table, box, polyline, chart.point
- `qualifier` - series, simple, const, input
- `identifier`

**Structure:**

- `block` - indentation-based block
- `comment` - `// ...`
