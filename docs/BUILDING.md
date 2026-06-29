# Building SageDOS

## Prerequisites

- **GCC** — C compiler for native ELF output
- **Python 3** — Required by the `sagemake` build system
- **Git** — For submodule management

## Setup

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/Night-Traders-Dev/SageDOS.git
cd SageDOS

# Setup dependencies (clones and builds SageLang + SageVM)
./sagesetup.sh
```

The `sagesetup.sh` script:
1. Clones `SageLang` and `SageVM` submodules
2. Builds SageLang from source
3. Verifies the `sage` binary is available

## Build System (`sagemake`)

The `sagemake` script is a Python 3 build orchestrator:

```bash
./sagemake [flags]
```

| Flag | Description |
|---|---|
| `--build` | Compile all `.sage` → native ELF via AOT C backend |
| `--clean` | Remove `build/` directory |
| `--test` | Run all test suites in `tests/` |
| `--run` | Execute compiled binary (or fallback to interpreter) |
| `--check` / `--lint` | Lint each source file with `sage lint` |
| `--debug` | Build with `SAGE_DEBUG` flag |
| `--rebuild-sage` | Force rebuild SageLang from submodule |
| `--install` | Copy binary to `/usr/local/bin` |

### Build Pipeline

1. **Source Verification** — Checks each `.sage` file is parseable
2. **Incremental Check** — SHA-256 hash of source directory; skips recompile if unchanged
3. **Compilation** — `sage --compile boot.sage -o build/sagedos`
4. **Binary Verification** — Confirms ELF binary exists and has valid size

### Module Build Order

The compiler processes files in dependency order:
```
bios_io.sage → int21.sage → token.sage → lexer.sage → ast.sage →
parser.sage → environment.sage → varstore.sage → filesystem.sage →
commands.sage → process.sage → registry.sage → interpreter.sage →
main.sage → kernel.sage → boot.sage
```

## Output

A successful build produces:
```
build/
└── sagedos    # ELF 64-bit x86-64 executable (~331 KB)
```

## Testing

```bash
# Run all test suites (22 suites)
./sagemake --test
```

Test files use the `std.testing` framework:
```sage
import std.testing
let t = std.testing

t.assert_eq(actual, expected, "test description")
```

### Test Architecture

Tests directly instantiate the interpreter pipeline:
```sage
from process     import BatchProcess
from interpreter import Interpreter
from lexer       import Lexer
from parser      import Parser

proc run(src):
    let proc = BatchProcess("TEST", [])
    let interp = Interpreter(proc)
    let tokens = Lexer(src + "\n").tokenize()
    let ast = Parser(tokens).parse()
    interp.run_program(ast)
    return interp
```

## Linting

```bash
# Lint all source files
./sagemake --lint
```

Runs `sage lint` on each `.sage` file and checks for syntax errors.

## Running

### Interactive Mode
```bash
./build/sagedos
```

### Script Mode
```bash
./build/sagedos path/to/script.bat [args...]
```

### Via Sage Interpreter
```bash
sage src/sage/boot.sage
```

## Development Workflow

```bash
# 1. Make changes to source files
# 2. Lint
./sagemake --lint

# 3. Test
./sagemake --test

# 4. Build + run
./sagemake --clean --build --run
```

## Dependencies

| Dependency | Path | Purpose |
|---|---|---|
| SageLang | `deps/SageLang/` | Language runtime and compiler |
| SageVM | `deps/SageVM/` | Virtual machine |
| MS-DOS 4.0 | `ref/MS-DOS/` | Reference source (MIT licensed) |
