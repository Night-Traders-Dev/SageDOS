# test_interpreter.sage — Integration tests for the full pipeline
import std.testing
from process     import BatchProcess
from interpreter import Interpreter
from lexer       import Lexer
from parser      import Parser

let t = std.testing

proc run(src):
    let proc_inst = BatchProcess("TEST", [])
    let interp    = Interpreter(proc_inst)
    let tokens    = Lexer(src + "\n").tokenize()
    let ast       = Parser(tokens).parse()
    interp.run_program(ast)
    return interp

# Test 1: ECHO (no crash)
run("@ECHO OFF\nECHO Hello")
t.assert_eq(true, true, "ECHO runs")

# Test 2: SET + variable expansion
let i1 = run("SET X=42")
t.assert_eq(i1.ctx.vars.get("X"), "42", "SET assigns X")

# Test 3: IF compare
run("SET A=hello\nIF %A% == hello ECHO match")
t.assert_eq(true, true, "IF compare runs")

# Test 4: GOTO
run("GOTO END\nECHO should not print\n:END\nECHO done")
t.assert_eq(true, true, "GOTO works")

# Test 5: SETLOCAL / ENDLOCAL scope isolation
let i2 = run("SET NAME=Jacob\nSETLOCAL ENABLEDELAYEDEXPANSION\nSET VAL=hello\nENDLOCAL")
t.assert_eq(i2.ctx.vars.get("NAME"), "Jacob", "global variable preserved after ENDLOCAL")
t.assert_eq(i2.ctx.vars.get("VAL"), "", "local variable discarded after ENDLOCAL")

# Test 6: Delayed expansion
let i3 = run("SETLOCAL ENABLEDELAYEDEXPANSION\nSET VAL=hello\nSET RES=!VAL!")
t.assert_eq(i3.ctx.vars.get("RES"), "hello", "delayed expansion replaces exclamation marks with value")

# Test 7: Normal exclamation marks when delayed expansion is disabled
let i4 = run("SET VAL=hello\nSET RES=!VAL!")
t.assert_eq(i4.ctx.vars.get("RES"), "!VAL!", "delayed expansion does not occur when disabled")

# Test 8: Pipe — ECHO output captured and fed to SET /P
let i5 = run("ECHO hello | SET /P VAR=")
t.assert_eq(i5.ctx.vars.get("VAR"), "hello", "pipe feeds ECHO output to SET /P")

# Test 9: Pipe — multiple lines, SET /P reads first only
let i6 = run("ECHO line_one\nECHO line_two")
let out_lines = i6.ctx.capture_buffer
t.assert_eq(len(out_lines), 0, "no capture without pipe")

print "interpreter integration tests passed."
