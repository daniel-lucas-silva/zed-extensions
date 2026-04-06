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
