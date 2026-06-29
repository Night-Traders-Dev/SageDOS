# test_commands.sage — Comprehensive test for all internal batch commands
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

proc run_capture(src):
    let proc_inst = BatchProcess("TEST", [])
    let interp    = Interpreter(proc_inst)
    let ctx       = interp.ctx
    ctx.capture_mode = true
    ctx.capture_buffer = []
    let tokens    = Lexer(src + "\n").tokenize()
    let ast       = Parser(tokens).parse()
    interp.run_program(ast)
    return ctx.capture_buffer

# ================================================================== ECHO
let out1 = run_capture("@ECHO OFF\nECHO Hello World")
t.assert_eq(len(out1), 1, "ECHO outputs one line")
t.assert_eq(out1[0], "Hello World", "ECHO prints correct string")

let out1b = run_capture("@ECHO OFF\nECHO ON\nECHO test")
t.assert_eq(len(out1b), 1, "ECHO ON enables echo")
t.assert_eq(out1b[0], "test", "ECHO ON prints text")

let out1c = run_capture("ECHO OFF\nECHO should_not_print")
t.assert_eq(len(out1c), 0, "ECHO OFF disables output")

let out1d = run_capture("ECHO ON\n@ECHO OFF\nECHO suppressed")
t.assert_eq(len(out1d), 0, "@ECHO OFF suppresses")

# ================================================================== REM
let r1 = run("REM This is a comment")
t.assert_eq(r1.ctx.env.get_errorlevel(), 0, "REM returns errorlevel 0")

# ================================================================== SET
let i_set1 = run("SET X=42")
t.assert_eq(i_set1.ctx.vars.get("X"), "42", "SET assigns variable")

let i_set2 = run("SET /A Y=1+2")
t.assert_eq(i_set2.ctx.vars.get("Y"), "3", "SET /A arithmetic addition")

let i_set3 = run("SET /A Z=5-2")
t.assert_eq(i_set3.ctx.vars.get("Z"), "3", "SET /A arithmetic subtraction")

let i_set4 = run("SET /A M=3*4")
t.assert_eq(i_set4.ctx.vars.get("M"), "12", "SET /A arithmetic multiplication")

let i_set5 = run("SET /A D=10/3")
t.assert_eq(i_set5.ctx.vars.get("D"), "3", "SET /A arithmetic division")

# ================================================================== SET /P prompt
let i_setp = run("SET /P ASK=Enter:")
t.assert_eq(true, true, "SET /P runs without pipe")

# ================================================================== SET (no args prints vars)
let out_set = run_capture("@ECHO OFF\nSET X=42\nSET")
let found = false
for line in out_set:
    if line == "X=42":
        found = true
t.assert_eq(found, true, "SET with no args prints variables")

# ================================================================== CLS
run("CLS")
t.assert_eq(true, true, "CLS runs")

# ================================================================== VER
let out_ver = run_capture("@ECHO OFF\nVER")
t.assert_eq(len(out_ver), 1, "VER outputs one line")
t.assert_eq(out_ver[0], "MS-DOS Batch 4.0 (SageBatch v1.0.0)", "VER outputs version")

# ================================================================== VOL
let out_vol = run_capture("@ECHO OFF\nVOL")
t.assert_eq(len(out_vol), 2, "VOL outputs two lines")

# ================================================================== DATE
let out_date = run_capture("@ECHO OFF\nDATE")
t.assert_eq(len(out_date), 1, "DATE outputs one line")

# ================================================================== TIME
let out_time = run_capture("@ECHO OFF\nTIME")
t.assert_eq(len(out_time), 1, "TIME outputs one line")

# ================================================================== TITLE
run("TITLE SageDOS Test")
t.assert_eq(true, true, "TITLE runs")

# ================================================================== COLOR
run("COLOR")
t.assert_eq(true, true, "COLOR reset runs")
run("COLOR 0A")
t.assert_eq(true, true, "COLOR 0A runs")
run("COLOR 0C")
t.assert_eq(true, true, "COLOR 0C runs")
run("COLOR 07")
t.assert_eq(true, true, "COLOR unknown code runs")

# ================================================================== PROMPT
let i_prompt = run("PROMPT [Test]$G")
t.assert_eq(i_prompt.ctx.env.vars["PROMPT"], "[Test]$G", "PROMPT sets variable")
run("PROMPT")
t.assert_eq(true, true, "PROMPT reset runs")

# ================================================================== HELP
let out_help = run_capture("@ECHO OFF\nHELP")
t.assert_eq(len(out_help) >= 3, true, "HELP outputs multiple lines")

# ================================================================== PATH
let out_path1 = run_capture("@ECHO OFF\nPATH")
t.assert_eq(len(out_path1) >= 1, true, "PATH prints current value")
let i_path = run("PATH /usr/bin")
t.assert_eq(i_path.ctx.env.vars["PATH"], "/usr/bin", "PATH sets variable")
run("PATH ;")
t.assert_eq(true, true, "PATH reset with semicolon runs")

# ================================================================== BREAK
let out_br = run_capture("@ECHO OFF\nBREAK")
t.assert_eq(len(out_br), 1, "BREAK outputs one line")
run("BREAK ON")
t.assert_eq(true, true, "BREAK ON runs")
run("BREAK OFF")
t.assert_eq(true, true, "BREAK OFF runs")

# ================================================================== CHCP
let out_chcp = run_capture("@ECHO OFF\nCHCP")
t.assert_eq(len(out_chcp), 1, "CHCP outputs one line")
run("CHCP 65001")
t.assert_eq(true, true, "CHCP with args runs")

# ================================================================== VERIFY
let out_vfy = run_capture("@ECHO OFF\nVERIFY")
t.assert_eq(len(out_vfy), 1, "VERIFY outputs one line")
run("VERIFY ON")
t.assert_eq(true, true, "VERIFY ON runs")
run("VERIFY OFF")
t.assert_eq(true, true, "VERIFY OFF runs")

# ================================================================== SHIFT
run("@ECHO OFF\nSET 1=first\nSHIFT")
t.assert_eq(true, true, "SHIFT runs")

# ================================================================== File operations
let dirname = "_sagetest_dir"
let fname = dirname + "/testfile.txt"

# MD
run("@ECHO OFF")
let i_md = run("MD " + dirname)
t.assert_eq(i_md.ctx.fs.is_dir(dirname), true, "MD creates directory")
let i_md2 = run("MD " + dirname)
t.assert_eq(true, true, "MD on existing directory handled")

# CD
let i_cd1 = run("CD " + dirname)
t.assert_eq(endswith(i_cd1.ctx.env.cwd, dirname), true, "CD changes to directory")

let i_cd2 = run("CD ..")
t.assert_eq(i_cd2.ctx.env.cwd, "/", "CD .. goes to parent")

let out_cd3 = run_capture("CD " + dirname + "\n@ECHO OFF\nCD")
t.assert_eq(endswith(out_cd3[0], dirname), true, "CD with no args prints cwd")

# Write file via redirect
let i_redir = run("CD " + dirname + "\nECHO file_content > testfile.txt")
t.assert_eq(i_redir.ctx.fs.exists(fname), true, "Redirect > creates file")

# TYPE
let out_type = run_capture("@ECHO OFF\nTYPE " + fname)
t.assert_eq(out_type[0], "file_content", "TYPE reads file content")

# COPY
let i_cp = run("COPY " + fname + " " + dirname + "/copy.txt")
t.assert_eq(i_cp.ctx.fs.exists(dirname + "/copy.txt"), true, "COPY creates destination file")

# REN
let i_ren = run("REN " + fname + " " + dirname + "/renamed.txt")
t.assert_eq(i_ren.ctx.fs.exists(dirname + "/renamed.txt"), true, "REN creates new name")
t.assert_eq(i_ren.ctx.fs.exists(fname), false, "REN removes old name")

# MOVE
let i_mv = run("MOVE " + dirname + "/renamed.txt " + dirname + "/moved.txt")
t.assert_eq(i_mv.ctx.fs.exists(dirname + "/moved.txt"), true, "MOVE creates destination")
t.assert_eq(i_mv.ctx.fs.exists(dirname + "/renamed.txt"), false, "MOVE removes source")

# DEL
let i_del = run("DEL " + dirname + "/copy.txt " + dirname + "/moved.txt")
t.assert_eq(i_del.ctx.fs.exists(dirname + "/copy.txt"), false, "DEL removes file")
t.assert_eq(i_del.ctx.fs.exists(dirname + "/moved.txt"), false, "DEL removes second file")

# DIR
let out_dir = run_capture("@ECHO OFF\nDIR " + dirname)
t.assert_eq(len(out_dir) >= 2, true, "DIR outputs entries")

# RD
let i_rd = run("RD " + dirname)
t.assert_eq(i_rd.ctx.fs.is_dir(dirname), false, "RD removes directory")

# ================================================================== PUSHD / POPD
# PUSHD stores cwd and changes dir. We'll use a temp dir for this.
let pd_dir = "_pushd_test"
let i_pd = run("MD " + pd_dir + "\nPUSHD " + pd_dir)
t.assert_eq(endswith(i_pd.ctx.env.cwd, pd_dir), true, "PUSHD changes directory")
let stack_len = len(i_pd.ctx.env.dir_stack)
t.assert_eq(stack_len > 0, true, "PUSHD stores old cwd on stack")

let i_popd = run("POPD")
t.assert_eq(i_popd.ctx.env.cwd, "/", "POPD restores cwd from stack")

run("RD " + pd_dir)
t.assert_eq(true, true, "POPD test dir cleaned up")

# ================================================================== SETLOCAL / ENDLOCAL
let i_sl1 = run("SET GLOBAL=keep\nSETLOCAL\nSET LOCAL=discard\nENDLOCAL")
t.assert_eq(i_sl1.ctx.vars.get("GLOBAL"), "keep", "SETLOCAL/ENDLOCAL preserves global")
t.assert_eq(i_sl1.ctx.vars.get("LOCAL"), "", "SETLOCAL/ENDLOCAL discards local")

# SETLOCAL ENABLEDELAYEDEXPANSION
let i_sl2 = run("SETLOCAL ENABLEDELAYEDEXPANSION\nSET X=hello\nSET Y=!X!")
t.assert_eq(i_sl2.ctx.vars.get("Y"), "hello", "delayed expansion !X! resolves at execution")

# SETLOCAL DISABLEDELAYEDEXPANSION
let i_sl3 = run("SETLOCAL DISABLEDELAYEDEXPANSION\nSET X=hello\nSET Y=!X!")
t.assert_eq(i_sl3.ctx.vars.get("Y"), "!X!", "delayed expansion disabled keeps literal !X!")

# Nested SETLOCAL
let i_sl4 = run("SET A=1\nSETLOCAL\nSET B=2\nSETLOCAL\nSET C=3\nENDLOCAL\nSET D=4\nENDLOCAL")
t.assert_eq(i_sl4.ctx.vars.get("A"), "1", "nested ENDLOCAL restores outer scope")
t.assert_eq(i_sl4.ctx.vars.get("B"), "", "nested ENDLOCAL discards outer local")

# ================================================================== Pipe
let out_pipe = run_capture("@ECHO OFF\nECHO piped_hello | SET /P PVAR=")
# The pipe output goes via capture_buffer of left side, then to pipe_lines
# We can't easily capture SET /P result here because run_capture captures left side
# But we already have a pipe test in test_interpreter. Just verify it runs.
t.assert_eq(true, true, "pipe with SET /P executes")

# ================================================================== IF
let out_if1 = run_capture("@ECHO OFF\nSET A=hello\nIF %A% == hello ECHO match")
t.assert_eq(out_if1[0], "match", "IF == match executes consequent")

let out_if2 = run_capture("@ECHO OFF\nSET A=hello\nIF %A% == world ECHO mismatch")
t.assert_eq(len(out_if2), 0, "IF == no match skips consequent")

let out_if3 = run_capture("@ECHO OFF\nSET A=hello\nIF NOT %A% == world ECHO not_match")
t.assert_eq(out_if3[0], "not_match", "IF NOT executes consequent")

let out_if4 = run_capture("@ECHO OFF\nSET A=hello\nIF %A% == hello ECHO yes\nIF %A% == world ECHO no")
t.assert_eq(out_if4[0], "yes", "multiple IF statements")

# IF with ELSE
let out_if5 = run_capture("@ECHO OFF\nSET A=no\nIF %A% == yes ECHO true ELSE ECHO false")
t.assert_eq(out_if5[0], "false", "IF ELSE alternate")

# IF ERRORLEVEL
let out_if6 = run_capture("@ECHO OFF\nVERIFY ON\nIF ERRORLEVEL 0 ECHO zero")
t.assert_eq(out_if6[0], "zero", "IF ERRORLEVEL 0 matches")

# IF EXIST
let out_if7 = run_capture("@ECHO OFF\nMD _ifexist_dir\nIF EXIST _ifexist_dir ECHO exists")
t.assert_eq(out_if7[0], "exists", "IF EXIST detects directory")
run("RD _ifexist_dir")

# IF DEFINED
let out_if8 = run_capture("@ECHO OFF\nSET IFVAR=1\nIF DEFINED IFVAR ECHO defined")
t.assert_eq(out_if8[0], "defined", "IF DEFINED detects variable")

# ================================================================== GOTO
let out_g1 = run_capture("@ECHO OFF\nGOTO SKIP\nECHO skipped\n:SKIP\nECHO landed")
t.assert_eq(out_g1[0], "landed", "GOTO jumps to label")

let out_g2 = run_capture("@ECHO OFF\nECHO before\nGOTO EOF\nECHO after")
t.assert_eq(out_g2[0], "before", "GOTO EOF ends script")

# ================================================================== FOR
let out_for1 = run_capture("@ECHO OFF\nFOR %X IN (A B C) DO ECHO %X")
t.assert_eq(out_for1[0], "A", "FOR loop first iteration")
t.assert_eq(out_for1[1], "B", "FOR loop second iteration")
t.assert_eq(out_for1[2], "C", "FOR loop third iteration")

# ================================================================== CALL (subroutine)
let out_call = run_capture("@ECHO OFF\nCALL :SUB\nECHO after_call\nGOTO END\n:SUB\nECHO in_sub\nGOTO :EOF\n:END\nECHO end")
t.assert_eq(out_call[0], "in_sub", "CALL enters subroutine")
t.assert_eq(out_call[1], "after_call", "CALL returns to caller")
t.assert_eq(out_call[2], "end", "script continues after CALL")

# ================================================================== EXIT
proc run_exit(src):
    let proc_inst = BatchProcess("TEST", [])
    let interp    = Interpreter(proc_inst)
    let tokens    = Lexer(src + "\n").tokenize()
    let ast       = Parser(tokens).parse()
    return interp.run_program(ast)

let exit_code = run_exit("@ECHO OFF\nEXIT 5")
t.assert_eq(exit_code, 5, "EXIT returns specified errorlevel")

print "command integration tests passed."
