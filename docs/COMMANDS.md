# SageBatch Command Reference

SageBatch implements the full MS-DOS Batch 4.0 command set with 35+ internal commands.

## Output Commands

### ECHO
```
ECHO [ON|OFF|message]
```
- `ECHO` (no args) — Displays current echo state
- `ECHO ON` — Enables command echoing
- `ECHO OFF` — Disables command echoing  
- `ECHO message` — Prints message to stdout
- `@ECHO OFF` — Suppress echo for this line only

### REM
```
REM [comment]
```
Comment — line is ignored by the interpreter.

### CLS
```
CLS
```
Clears the screen (ANSI escape codes).

## Variable Commands

### SET
```
SET [variable=[value]]
SET /A variable=expression
SET /P variable=[prompt]
```
- `SET` — Display all environment variables
- `SET name=value` — Assign value to variable
- `SET /A name=expr` — Arithmetic evaluation (`+`, `-`, `*`, `/`)
- `SET /P name=prompt` — Prompt for user input

### SETLOCAL / ENDLOCAL
```
SETLOCAL [ENABLEDELAYEDEXPANSION|DISABLEDELAYEDEXPANSION]
...
ENDLOCAL
```
- `SETLOCAL` — Push variable scope (snapshot all variables)
- `SETLOCAL ENABLEDELAYEDEXPANSION` — Enable `!VAR!` syntax
- `SETLOCAL DISABLEDELAYEDEXPANSION` — Disable delayed expansion
- `ENDLOCAL` — Pop variable scope, restore snapshot

Variables set between SETLOCAL and ENDLOCAL are discarded. Nesting is supported.

### Delayed Expansion
```
SETLOCAL ENABLEDELAYEDEXPANSION
SET X=hello
SET Y=!X!        # Y = "hello" (evaluated at execution time)
```
When delayed expansion is enabled, `!VAR!` tokens are resolved at execution time rather than parse time (like `%VAR%`).

## Directory Commands

### CD / CHDIR
```
CD [path]
```
- `CD` — Display current working directory
- `CD path` — Change working directory
- `CD ..` — Go to parent directory

### MD / MKDIR
```
MD path
```
Create a new directory.

### RD / RMDIR
```
RD path
```
Remove an empty directory.

### DIR
```
DIR [path]
```
List directory contents with file count.

### PUSHD / POPD
```
PUSHD path
POPD
```
- `PUSHD` — Save current directory and change to new path
- `POPD` — Return to directory saved by last PUSHD

## File Commands

### TYPE
```
TYPE filename
```
Display contents of a text file.

### COPY
```
COPY source destination
```
Copy a file from source to destination.

### MOVE
```
MOVE source destination
```
Move/rename a file from source to destination.

### DEL / ERASE
```
DEL file1 [file2 ...]
```
Delete one or more files.

### REN / RENAME
```
REN oldname newname
```
Rename a file.

## Control Flow

### IF
```
IF [NOT] condition command [ELSE command]
```
Conditions:
- `string1 == string2` — String equality
- `string1 EQU string2` — String equality (alias)
- `string1 NEQ string2` — String inequality
- `string1 LSS string2` — Less than (numeric)
- `string1 LEQ string2` — Less than or equal (numeric)
- `string1 GTR string2` — Greater than (numeric)
- `string1 GEQ string2` — Greater than or equal (numeric)
- `EXIST path` — File/directory exists
- `DEFINED variable` — Variable is defined
- `ERRORLEVEL n` — Errorlevel >= n

### FOR
```
FOR %variable IN (item1 item2 ...) DO command
```
Iterates over a list, setting the variable to each item and executing the command.

### GOTO
```
GOTO label
GOTO EOF
```
Jump to a label (`:label`) in the script. `GOTO EOF` exits the current script or subroutine.

### CALL
```
CALL :subroutine [args...]
CALL script.bat [args...]
```
Call a subroutine (label) within the current script, or execute another batch file.

## Redirection and Pipes

### Output Redirection
```
command > file     # Truncate file, write stdout
command >> file    # Append stdout to file
```

### Pipes
```
command1 | command2
```
Pipes stdout of `command1` to stdin of `command2`. Works with `SET /P` for capturing output into variables:
```
ECHO hello | SET /P VAR=
```

## System Commands

### PAUSE
```
PAUSE
```
Display "Press any key to continue..." and wait for input.

### EXIT
```
EXIT [code]
```
Exit the script or shell with an optional errorlevel code.

### VER
```
VER
```
Display SageBatch version: `MS-DOS Batch 4.0 (SageBatch v1.0.0)`

### VOL
```
VOL
```
Display volume label and serial number.

### DATE
```
DATE
```
Display the current date.

### TIME
```
TIME
```
Display the current time.

### TITLE
```
TITLE text
```
Set the terminal window title (ANSI escape).

### COLOR
```
COLOR [attr]
```
Set console colors. Supported codes:
- (no args) — Reset to default
- `0A` — Green text
- `0C` — Red text

### PROMPT
```
PROMPT [text]
```
Set the command prompt. Special sequences:
- `$P` — Current path
- `$G` — `>` character
- `$L` — `<` character
- `$N` — Drive letter
- `$Q` — `=` character
- `$$` — `$` character

### PATH
```
PATH [path]
```
- `PATH` — Display current search path
- `PATH value` — Set search path
- `PATH ;` — Clear search path

### VERIFY
```
VERIFY [ON|OFF]
```
Display or set verify mode.

### BREAK
```
BREAK [ON|OFF]
```
Display or set break checking.

### CHCP
```
CHCP [codepage]
```
Display or set active code page.

### SHIFT
```
SHIFT
```
Shift positional parameters (`%0`-`%9`) left by one.

### HELP
```
HELP
```
Display list of available internal commands.

## Error Levels

Commands return an errorlevel code:
- `0` — Success
- `1` or higher — Error

Use `IF ERRORLEVEL n` to check the last command's exit code.
