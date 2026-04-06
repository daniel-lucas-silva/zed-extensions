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
  (type) @type.builtin)

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
  (type) @type.builtin)

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
