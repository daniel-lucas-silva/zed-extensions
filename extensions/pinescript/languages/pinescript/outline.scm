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
