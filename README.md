# Pine Script Extension for Zed

Syntax highlighting and snippets support for TradingView's Pine Script (v5/v6) in the Zed editor.

## Features

- 🎨 **Syntax Highlighting** - Full highlighting for Pine Script keywords, functions, types, and built-in variables
- 📦 **40+ Snippets** - Quick code templates for indicators, strategies, functions, and common patterns
- 🔧 **Tree-sitter Grammar** - Powered by [tree-sitter-pine](https://github.com/kvarenzn/tree-sitter-pine)

## Installation

### From Source (Development)

1. Clone this repository:

```bash
git clone https://github.com/daniel-lucas-silva/zed-extensions.git
```

2. Install the extension in Zed:
   - Open Zed
   - Go to `Extensions` → `Install Dev Extension`
   - Select the `zed-extensions` folder

### From Zed Extensions (when published)

1. Open Zed
2. Go to `Extensions` → `Search for "Pine Script"`
3. Click Install

## Snippets

### Declarations

| Snippet     | Description            |
| ----------- | ---------------------- |
| `indicator` | Create a new indicator |
| `strategy`  | Create a new strategy  |
| `library`   | Create a new library   |

### Technical Analysis

| Snippet | Description                           |
| ------- | ------------------------------------- |
| `sma`   | Simple Moving Average (`ta.sma`)      |
| `ema`   | Exponential Moving Average (`ta.ema`) |
| `rsi`   | Relative Strength Index (`ta.rsi`)    |
| `macd`  | MACD indicator                        |
| `bb`    | Bollinger Bands                       |

### Inputs

| Snippet          | Description     |
| ---------------- | --------------- |
| `inputint`       | Integer input   |
| `inputfloat`     | Float input     |
| `inputbool`      | Boolean input   |
| `inputcolor`     | Color input     |
| `inputsource`    | Source input    |
| `inputtimeframe` | Timeframe input |
| `inputsymbol`    | Symbol input    |

### Plotting

| Snippet | Description            |
| ------- | ---------------------- |
| `plot`  | Plot a series          |
| `hline` | Draw horizontal line   |
| `fill`  | Fill between two plots |

### Control Flow

| Snippet  | Description       |
| -------- | ----------------- |
| `if`     | If statement      |
| `ifelse` | If-else statement |
| `for`    | For loop          |
| `while`  | While loop        |
| `switch` | Switch expression |

### Strategy

| Snippet | Description                   |
| ------- | ----------------------------- |
| `entry` | Strategy entry                |
| `close` | Strategy close                |
| `exit`  | Strategy exit with stop/limit |

### And more...

- Arrays, matrices, drawing objects (labels, lines, boxes, tables)
- Color functions, time functions, bar state checks
- Method definitions, variable declarations

## Supported File Extensions

- `.pine`
- `.pinescript`

## Structure

```
zed-extensions/
├── extension.toml              # Extension manifest
├── languages/
│   └── pinescript/
│       ├── config.toml         # Language configuration
│       └── highlights.scm      # Syntax highlighting queries
└── snippets/
    └── pinescript.json         # Code snippets
```

## Development

### Adding New Snippets

Edit `snippets/pinescript.json` and add entries following this format:

```json
{
  "snippet-name": {
    "prefix": "trigger",
    "body": ["code line 1", "code line 2"],
    "description": "Description of the snippet"
  }
}
```

### Modifying Syntax Highlighting

Edit `languages/pinescript/highlights.scm` using Tree-sitter query syntax.

## Credits

- **Tree-sitter Grammar**: [kvarenzn/tree-sitter-pine](https://github.com/kvarenzn/tree-sitter-pine)
- **Reference Data**: Based on [7kylor/pinescript-extension](https://github.com/7kylor/pinescript-extension) (VS Code extension)

## License

MIT

## Contributing

Contributions are welcome! Please open an issue or PR if you'd like to add features or fix bugs.
