# SageDOS Architecture

## Three-Layer Design

SageDOS mirrors the classic MS-DOS three-layer architecture:

```
┌─────────────────────────────────────────┐
│               USER SPACE                │
│  ┌───────────────────────────────────┐  │
│  │  SageBatch (COMMAND.COM)          │  │
│  │  Interactive shell + batch interp │  │
│  └──────────────┬────────────────────┘  │
│                 │ INT 21h calls          │
│  ┌──────────────▼────────────────────┐  │
│  │  SageDOS Kernel (MSDOS.SYS)      │  │
│  │  File I/O, process, memory mgmt  │  │
│  └──────────────┬────────────────────┘  │
│                 │                       │
│  ┌──────────────▼────────────────────┐  │
│  │  BIOS Layer (IO.SYS)             │  │
│  │  Hardware abstraction            │  │
│  └──────────────────────────────────┘  │
│                 │                       │
│         ┌───────▼───────┐               │
│         │   HARDWARE    │               │
│         └───────────────┘               │
└─────────────────────────────────────────┘
```

## Module Map

### BIOS Layer — `src/sage/bios_io.sage`
Hardware Abstraction Layer. Translates low-level I/O requests:
- `read_char()` — Read character from console
- `print_char()` — Print character to console
- `print_string()` — Print null-terminated string

### Kernel Layer — `src/sage/kernel.sage`, `int21.sage`
Core OS services:
- **`kernel.sage`** — System initialization, shell execution, shutdown
- **`int21.sage`** — INT 21h dispatcher (AH=01h, 02h, 09h, 4Ch implemented)

### Boot — `src/sage/boot.sage`
Entry point. Initializes hardware → kernel → shell pipeline.

### SageBatch Shell — `src/sage/command_com/`

The command interpreter is a pipeline of 14 modules:

```
Source (.BAT) → Lexer → Parser → Interpreter
     │             │        │          │
     ▼             ▼        ▼          ▼
  Token types   Tokenize   AST      Execute
  (token.sage) (lexer.sage) (ast.sage, parser.sage) (interpreter.sage)
                                    │
                          ┌─────────┼─────────┐
                          ▼         ▼         ▼
                     Environment  VarStore  FileSystem
                     (env.sage)  (var.sage) (fs.sage)
                          │         │         │
                          └────┬────┴────┬────┘
                               ▼         ▼
                         CommandContext  CommandRegistry
                         (context.sage) (registry.sage)
                               │         │
                               ▼         ▼
                          Commands     Dispatch
                         (commands.sage)
```

#### Key Modules

| Module | Purpose |
|---|---|
| `token.sage` | Token type constants and Token class |
| `lexer.sage` | Converts `.BAT` source to token stream |
| `ast.sage` | AST node types (Command, Assignment, If, For, etc.) |
| `parser.sage` | Recursive-descent parser producing AST |
| `interpreter.sage` | Tree-walking interpreter with GOTO/CALL |
| `process.sage` | BatchProcess — binds env, vars, fs, call stack |
| `context.sage` | CommandContext — variable expansion, I/O routing, pipes |
| `environment.sage` | DOS environment block (PATH, PROMPT, CWD) |
| `varstore.sage` | Scoped variable store with `%VAR%` and `!VAR!` |
| `filesystem.sage` | DOS-path filesystem with normalization |
| `commands.sage` | 35+ internal command implementations |
| `registry.sage` | Command dispatch table + external exec |
| `batch.sage` | Standalone entry point for SageBatch |
| `main.sage` | CommandCom class wrapping interactive + script modes |

## Execution Flow

### Interactive Mode
```
boot.sage → kernel.execute_shell()
  → CommandCom().run()
    → run_interactive()
      → loop: input → Lexer → Parser → Interpreter.exec_node()
```

### Script Mode
```
boot.sage → kernel.execute_shell()
  → CommandCom().run()
    → run_script()
      → io_readfile → Lexer → Parser → Interpreter.run_program()
```

### Command Dispatch
```
exec_node(Command)
  → expand_args()        # Resolve %VAR% and !VAR!
  → echo display         # Echo command if enabled
  → registry.dispatch()  # Look up or fallback to sys_exec
    → command handler    # Execute and return errorlevel
```

## Variable Expansion

### Parse-time Expansion (`%VAR%`)
```
SET X=hello
ECHO %X%    # X expands to "hello" at parse time
```

Handled by `lexer.sage` → `Token(is_delayed=false)` → `context.expand_token()` → `varstore.get()`.

### Delayed Expansion (`!VAR!`)
```
SETLOCAL ENABLEDELAYEDEXPANSION
SET X=hello
SET Y=!X!    # X expands to "hello" at execution time
```

Handled by `lexer.sage` → `Token(is_delayed=true)` → `context.expand_token()` checks `environment.delayed_expansion` flag.

## Scoping (SETLOCAL/ENDLOCAL)

```
SETLOCAL
  → environment.setlocal()
    → snapshot all vars, cwd, delayed_expansion → push to setlocal_stack
...
ENDLOCAL
  → environment.endlocal()
    → pop from setlocal_stack → restore vars, cwd, delayed_expansion
```

Supports nesting — each `SETLOCAL` pushes a frame, each `ENDLOCAL` pops.

## Pipe Implementation

```
command1 | command2
```

1. `context.capture_mode = true` — redirect `write_out()` to in-memory buffer
2. Execute `command1` — output collects in `capture_buffer`
3. `context.capture_mode = false` — restore normal routing
4. Set `context.pipe_lines` to captured output
5. Execute `command2` — `read_line()` reads from `pipe_lines`

## Filesystem Abstraction

DOS paths are mapped to host filesystem:
- `/` → `.` (current directory)
- `/foo/bar` → `./foo/bar`
- `testdir` (relative) → `./testdir` (from CWD)
- `\` → `/` (backslash normalization)
- `/path/..` → parent directory normalization
