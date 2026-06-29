# SageDOS

> A clean-room MS-DOS 4.0 clone implemented entirely in [SageLang](https://github.com/Night-Traders-Dev/SageLang), running on [SageVM](https://github.com/Night-Traders-Dev/SageVM) or natively compiled to C/ELF.

SageDOS is a faithful, modular reimplementation of the classic MS-DOS three-layer architecture — BIOS, kernel, and command shell — written in pure SageLang. It includes **SageBatch**, a full MS-DOS Batch 4.0 compatible command interpreter with 35+ internal commands, variable scoping, delayed expansion, pipes, and redirection.

## Architecture

```
┌──────────────────────────────────────────────────┐
│  COMMAND.COM  —  SageBatch shell (interactive +  │
│                  batch scripting with 35+ cmds)   │
├──────────────────────────────────────────────────┤
│  MSDOS.SYS    —  Kernel + INT 21h dispatcher     │
├──────────────────────────────────────────────────┤
│  IO.SYS       —  BIOS / Hardware Abstraction     │
└──────────────────────────────────────────────────┘
```

| MS-DOS Layer | SageDOS Module | Description |
|---|---|---|
| `IO.SYS` | `src/sage/bios_io.sage` | Hardware Abstraction Layer |
| `MSDOS.SYS` | `src/sage/kernel.sage`, `int21.sage` | Kernel + INT 21h system calls |
| `COMMAND.COM` | `src/sage/command_com/` (14 modules) | SageBatch shell |

## Features

### Implementation Status

| Phase | Component | Status |
|---|---|---|
| 1 | Lexer (tokenizer) | Done |
| 2 | Parser (recursive-descent) | Done |
| 3 | Interpreter (tree-walking) | Done |
| 4 | Environment (PATH, PROMPT, CWD) | Done |
| 5 | Internal Commands (35+) | Done |
| 6 | Redirection (`>`, `>>`) | Done |
| 7 | Pipes (`\|`) | Done |

### SageBatch Built-in Commands

```
ECHO   SET    REM    PAUSE   CLS     EXIT    CD/CHDIR
MD     RD     DIR    TYPE    COPY    MOVE    DEL/ERASE
REN    SHIFT  VER    HELP    TITLE   COLOR   PROMPT
DATE   TIME   VOL    VERIFY  PUSHD   POPD    PATH
BREAK  CHCP   SETLOCAL  ENDLOCAL  IF    FOR    GOTO   CALL
```

### Key Features

- **SET /A** — Arithmetic expressions (`+`, `-`, `*`, `/`)
- **SET /P** — Prompted input with pipe support
- **SETLOCAL / ENDLOCAL** — Scoped variable snapshots
- **Delayed expansion** — `!VAR!` syntax (`ENABLEDELAYEDEXPANSION`)
- **IF** — `==`, `EQU`, `NEQ`, `LSS`, `LEQ`, `GTR`, `GEQ`, `NOT`, `ELSE`, `EXIST`, `DEFINED`, `ERRORLEVEL`
- **FOR** — `FOR %X IN (list) DO command`
- **GOTO** — Labels (`:label`), `GOTO EOF`
- **CALL** — Subroutine calls with call stack
- **Redirection** — `>` (truncate), `>>` (append)
- **Pipes** — `|` connects stdout of left to stdin of right

## Repository Layout

```
SageDOS/
├── src/sage/
│   ├── bios_io.sage          # Hardware Abstraction Layer
│   ├── kernel.sage           # SageDOS kernel
│   ├── int21.sage            # INT 21h dispatcher
│   ├── boot.sage             # Entry point / boot sequence
│   └── command_com/          # SageBatch shell
│       ├── token.sage        # Token types
│       ├── lexer.sage        # Batch tokenizer (%VAR%, !VAR!)
│       ├── ast.sage          # AST node definitions
│       ├── parser.sage       # Recursive-descent parser
│       ├── interpreter.sage  # Tree-walking interpreter
│       ├── process.sage      # BatchProcess / exec context
│       ├── context.sage      # CommandContext (vars, I/O, pipes)
│       ├── environment.sage  # DOS environment block
│       ├── varstore.sage     # Scoped variable store
│       ├── filesystem.sage   # DOS-path filesystem wrapper
│       ├── commands.sage     # 35+ internal command handlers
│       ├── registry.sage     # Command dispatch table
│       ├── batch.sage        # Standalone SageBatch entrypoint
│       └── main.sage         # CommandCom class
├── tests/                    # 22 test suites
├── examples/                 # Example batch scripts
├── docs/                     # Documentation
├── deps/                     # Git submodules (SageLang, SageVM)
├── ref/MS-DOS/               # Reference MS-DOS 4.0 source
├── sagemake                  # Build system (Python)
├── sagesetup.sh              # Setup script
└── README.md
```

## Building and Running

### Quick Start

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/Night-Traders-Dev/SageDOS.git
cd SageDOS

# Setup dependencies
./sagesetup.sh

# Build SageDOS
./sagemake --build

# Run the shell (interactive mode)
./build/sagedos

# Run a batch script
./build/sagedos examples/test_all.bat
```

### Build Commands

```bash
./sagemake --build       # Compile to native ELF
./sagemake --clean       # Remove build artifacts
./sagemake --test        # Run all test suites
./sagemake --lint        # Lint all source files
./sagemake --run         # Run compiled binary
./sagemake --debug       # Build with debug symbols
./sagemake --install     # Install to /usr/local/bin
```

## Documentation

- [SageBatch Documentation Website](https://night-traders-dev.github.io/SageBatch-Docs/) — Full interactive docs
- [Command Reference](docs/COMMANDS.md) — Full list of internal commands
- [Architecture](docs/ARCHITECTURE.md) — Design and module overview
- [Building](docs/BUILDING.md) — Build system and compilation details

## License

SageDOS is a clean-room educational implementation. See reference MS-DOS 4.0 sources under `ref/MS-DOS/` (MIT licensed).
