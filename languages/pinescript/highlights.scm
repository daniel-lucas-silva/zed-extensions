;; Pine Script Tree-sitter Syntax Highlighting
;; Based on kvarenzn/tree-sitter-pine grammar

;; ============================================
;; Keywords
;; ============================================

[
  "indicator"
  "strategy"
  "library"
] @keyword.function

[
  "if"
  "else"
  "for"
  "to"
  "while"
  "switch"
  "=>"
] @keyword.control

[
  "var"
  "varip"
  "const"
] @keyword.storage

[
  "and"
  "or"
  "not"
] @keyword.operator

[
  "true"
  "false"
  "na"
] @constant.builtin

;; ============================================
;; Types
;; ============================================

[
  "int"
  "float"
  "bool"
  "color"
  "string"
  "line"
  "label"
  "box"
  "table"
  "array"
  "matrix"
  "chart.point"
] @type.builtin

;; ============================================
;; Functions
;; ============================================

;; Built-in functions
(call_expression
  function: (identifier) @function.builtin
  (#match? @function.builtin "^(plot|plotshape|plotchar|plotarrow|plotcandle|plotbar|plotline|plotarea|plotbb|fill|hline|bgcolor|barcolor|alert|barcolor|linefill|alertcondition)$"))

;; Technical analysis functions (ta.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^ta\\."))

;; Math functions (math.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^math\\."))

;; String functions (str.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^str\\."))

;; Array functions (array.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^array\\."))

;; Matrix functions (matrix.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^matrix\\."))

;; Color functions (color.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^color\\."))

;; Strategy functions (strategy.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^strategy\\."))

;; Input functions (input.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^input\\."))

;; Request functions (request.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^request\\."))

;; Ticker functions (ticker.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^ticker\\."))

;; Time functions (time.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^time\\."))

;; Syminfo functions (syminfo.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^syminfo\\."))

;; Barstate functions (barstate.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^barstate\\."))

;; Dayofweek functions (dayofweek.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^dayofweek\\."))

;; Session functions (session.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^session\\."))

;; Shape functions (shape.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^shape\\."))

;; Location functions (location.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^location\\."))

;; Size functions (size.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^size\\."))

;; Style functions (style.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^style\\."))

;; Position functions (position.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^position\\."))

;; Text functions (text.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^text\\."))

;; Xloc functions (xloc.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^xloc\\."))

;; Yloc functions (yloc.*)
(call_expression
  function: (identifier) @function.method
  (#match? @function.method "^yloc\\."))

;; ============================================
;; Variables and Identifiers
;; ============================================

;; Built-in variables
((identifier) @constant.builtin
  (#match? @constant.builtin "^(open|high|low|close|volume|time|hl2|hlc3|ohlc4|hlcc4|bar_index|barstate|barmerge|currency|chart\.point|dayofweek|display|dividends|earnings|extend|format|fraction|label\.all|line\.all|box\.all|table\.all|level|lines|market|minimize|minute|month|na|n|nz|ohlc4|order|orders|period|plot\.all|realtime|scale|second|seconds|session|splits|strategy|syminfo|timeframe|timestamp|trackprice|week|year|xloc|yloc|size|align|direction|frac|fractal|gap|gradation|inherit|linefill|log|scale|splits|currency|display|order|orders|position|scale|size|strategy|text|trackprice|xloc|yloc)$"))

;; User-defined function calls
(call_expression
  function: (identifier) @function)

;; Variable declarations
(variable_declaration
  name: (identifier) @variable)

;; Parameter names
(formal_parameter
  name: (identifier) @variable.parameter)

;; ============================================
;; Literals
;; ============================================

(number) @number

(string) @string

(color) @string.special

(comment) @comment

;; ============================================
;; Operators
;; ============================================

[
  "+"
  "-"
  "*"
  "/"
  "%"
  "=="
  "!="
  "<"
  ">"
  "<="
  ">="
  "="
  ":="
  "+="
  "-="
  "*="
  "/="
  "%="
  "?"
  ":"
  "=>"
] @operator

;; ============================================
;; Punctuation
;; ============================================

[
  ","
  "."
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation

;; ============================================
;; Special
;; ============================================

;; Method calls (identifier.method)
(field_expression
  object: (identifier) @variable
  field: (identifier) @property)

;; ============================================
;; Deprecated/Old Pine Script v4 patterns
;; ============================================

;; v4 style functions (still valid but deprecated style)
(call_expression
  function: (identifier) @function.builtin
  (#match? @function.builtin "^(security|study|plot|fill|hline|bgcolor|alertcondition|input|strategy\.entry|strategy\.exit|strategy\.close|strategy\.cancel|strategy\.cancel_all)$"))
