# batch.sage — SageBatch entrypoint
# Usage: sage src/sage/batch.sage [script.bat] [args...]
#
# If no script is given, enters interactive command-line mode.
# Phases: 0 (repo) ✓  1 (lexer) ✓  2 (parser) ✓  3 (interpreter) ✓
#         4 (env) ✓   5 (commands) ✓  6 (redirect) ✓  7 (pipes) ✓

from token       import Token, TOK_WORD, TOK_STRING, TOK_VARIABLE, TOK_LABEL, TOK_OPERATOR, TOK_REDIRECT, TOK_PIPE, TOK_NEWLINE, TOK_EOF, TOK_AMP, TOK_PAREN_L, TOK_PAREN_R, TOK_AT
from process     import BatchProcess
from interpreter import Interpreter
from lexer       import Lexer
from parser      import Parser
import sys
import io

class CommandCom:
    proc init(self):
        return

    proc print_banner(self):
        print "SageBatch v1.0.0 — MS-DOS Batch 4.0 Clone in Pure SageLang"
        print "Type HELP for a list of commands.  Type EXIT to quit."
        print ""

    proc run_interactive(self, process):
        self.print_banner()
        let interp = Interpreter(process)
        while true:
            let prompt = process.env.render_prompt()
            let line   = input(prompt)
            if line == nil:
                break
            line = strip(line)
            if len(line) == 0:
                continue
            if upper(line) == "EXIT":
                break
            try:
                let lexer  = Lexer(line + "\n")
                let tokens = lexer.tokenize()
                let parser = Parser(tokens)
                let ast    = parser.parse()
                let ret    = interp.run_program(ast)
            catch e:
                print "Error: " + str(e)

    proc run_script(self, process):
        let source = io_readfile(process.script_path)
        if source == nil:
            print "SageBatch: File not found: " + process.script_path
            return
        let interp  = Interpreter(process)
        let lexer   = Lexer(source)
        let tokens  = lexer.tokenize()
        let parser  = Parser(tokens)
        let ast     = parser.parse()
        interp.run_program(ast)

    proc run(self, process):
        if process.script_path == "INTERACTIVE":
            self.run_interactive(process)
        else:
            self.run_script(process)
