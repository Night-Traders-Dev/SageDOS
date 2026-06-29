# interpreter.sage — Tree-walking batch interpreter
# Phase 3: Executes a Program AST produced by parser.sage.
# Implements: GOTO jumps, IF conditionals, FOR loops,
# CALL nesting, variable expansion, redirection, and pipes.

from ast      import Program, Command, Assignment, IfStatement, ForStatement, LabelNode, GotoNode, CallNode, RedirectNode, PipeNode, BlockNode
from registry import CommandRegistry
from lexer    import Lexer
from parser   import Parser
import io
import sys

# Sentinel exception class for GOTO
class GotoSignal:
    proc init(self, target):
        self.target = target

# Sentinel for EXIT
class ExitSignal:
    proc init(self, code):
        self.code = code

class Interpreter:
    proc init(self, process):
        self.process  = process
        self.ctx      = process.make_context(process.batch_args)
        self.registry = CommandRegistry(self.ctx)
        self.labels   = {}     # name → statement index in flat list
        self.stmts    = []     # flattened statement list for GOTO

    # ------------------------------------------------------------------ label table

    proc build_label_table(self, program):
        self.stmts = program.statements
        let i = 0
        for stmt in self.stmts:
            if stmt.type == "LabelNode":
                let lname = stmt.name
                let uname = upper(lname)
                let ldict = self.labels
                ldict[uname] = i
            i = i + 1

    # ------------------------------------------------------------------ condition evaluation

    proc eval_condition(self, cond):
        let ctype = cond["type"]
        if ctype == "EXIST":
            let c = self.ctx
            let v = c.vars
            let path = v.expand(cond["path"])
            let fs = c.fs
            return fs.exists(path)
        if ctype == "DEFINED":
            let c = self.ctx
            let v = c.vars
            let val = v.get(cond["name"])
            return val != "" and val != nil
        if ctype == "ERRORLEVEL":
            let n = tonumber(cond["value"])
            return self.ctx.env.get_errorlevel() >= n
        if ctype == "CMP":
            let c = self.ctx
            let v = c.vars
            let left  = v.expand(cond["left"])
            let right = v.expand(cond["right"])
            let op    = upper(cond["op"])
            if op == "==":
                return left == right
            if op == "EQU":
                return left == right
            if op == "NEQ":
                return left != right
            if op == "LSS":
                return tonumber(left) < tonumber(right)
            if op == "LEQ":
                return tonumber(left) <= tonumber(right)
            if op == "GTR":
                return tonumber(left) > tonumber(right)
            if op == "GEQ":
                return tonumber(left) >= tonumber(right)
        return false

    # ------------------------------------------------------------------ token arg expansion

    proc expand_args(self, args):
        let out = []
        for arg in args:
            push(out, self.ctx.expand_token(arg))
        return out

    # ------------------------------------------------------------------ execute single node

    proc exec_node(self, node):
        if node == nil:
            return 0

        let ntype = node.type

        if ntype == "LabelNode":
            return 0

        if ntype == "Assignment":
            let name = node.name
            let is_arith = false
            let is_prompt = false
            if len(name) > 2 and slice(name, 0, 2) == "/A":
                let name_tmp = slice(name, 2, len(name))
                name = strip(name_tmp)
                is_arith = true
            elif len(name) > 2 and slice(name, 0, 2) == "/P":
                let name_tmp = slice(name, 2, len(name))
                name = strip(name_tmp)
                is_prompt = true
            
            let c = self.ctx
            let v = c.vars
            let val = v.expand(node.value)
            
            if is_prompt:
                c.write_out(val)
                let user_input = c.read_line()
                if user_input == nil:
                    user_input = ""
                v.set(name, user_input)
                let env = c.env
                env.set_errorlevel(0)
                return 0
            
            if is_arith:
                let op_idx = -1
                let i = 0
                let op_char = ""
                while i < len(val):
                    let ch = val[i]
                    if ch == "+" or ch == "-" or ch == "*" or ch == "/":
                        op_idx = i
                        op_char = ch
                        break
                    i = i + 1
                if op_idx != -1:
                    let left_tmp = slice(val, 0, op_idx)
                    let right_tmp = slice(val, op_idx + 1, len(val))
                    let left = strip(left_tmp)
                    let right = strip(right_tmp)
                    
                    let left_val = v.get(left)
                    if left_val != "" and left_val != nil: left = left_val
                    let right_val = v.get(right)
                    if right_val != "" and right_val != nil: right = right_val
                    
                    let left_num = tonumber(left)
                    let right_num = tonumber(right)
                    if left_num == nil or right_num == nil:
                        print "CRASH_BUG: left='" + str(left) + "' right='" + str(right) + "'"
                        val = "0"
                    else:
                        if op_char == "+": val = str(left_num + right_num)
                        if op_char == "-": val = str(left_num - right_num)
                        if op_char == "*": val = str(left_num * right_num)
                        if op_char == "/": 
                            if right_num == 0: val = "0"
                            else: val = str(left_num / right_num)
                else:
                    let val_var = v.get(val)
                    if val_var != "" and val_var != nil: val = val_var
                    val = str(tonumber(val))

            v.set(name, val)
            let env = c.env
            env.set_errorlevel(0)
            return 0

        if ntype == "GotoNode":
            let target = upper(node.target)
            let sig = {}
            sig["__signal"] = "GOTO"
            sig["target"] = target
            return sig

        if ntype == "IfStatement":
            let result = self.eval_condition(node.condition)
            if node.negated:
                result = not result
            if result:
                return self.exec_node(node.consequent)
            elif node.alternate != nil:
                return self.exec_node(node.alternate)
            return 0

        if ntype == "ForStatement":
            let c = self.ctx
            let v = c.vars
            v.push_scope()
            let ret = 0
            for tok in node.in_list:
                let val = c.expand_token(tok)
                v.set_local(node.var_name, val)
                ret = self.exec_node(node.body)
                if type(ret) == "dict" and dict_has(ret, "__signal"):
                    break
            v.pop_scope()
            return ret

        if ntype == "CallNode":
            let args = self.expand_args(node.args)
            if node.is_subroutine:
                let target = upper(node.target)
                let sig = {}
                sig["__signal"] = "CALL"
                sig["target"] = target
                sig["args"] = args
                return sig
            else:
                return self.run_file(node.target, args)

        if ntype == "BlockNode":
            let ret = 0
            for s in node.statements:
                ret = self.exec_node(s)
                if type(ret) == "dict" and dict_has(ret, "__signal"):
                    return ret
            return ret

        if ntype == "RedirectNode":
            let c = self.ctx
            let v = c.vars
            let filename = v.expand(node.filename)
            let old_stdout = c.stdout
            if node.op == ">":
                c.fs.write_file(filename, "")
                c.stdout = filename
            elif node.op == ">>":
                c.stdout = filename
            let ret = self.exec_node(node.inner)
            c.stdout = old_stdout
            return ret

        if ntype == "PipeNode":
            let c = self.ctx
            let saved_capture = c.capture_mode
            let saved_buffer = c.capture_buffer
            c.capture_mode = true
            let arr = []
            c.capture_buffer = arr
            let ret1 = self.exec_node(node.left)
            c.capture_mode = saved_capture
            let pipe_output = c.capture_buffer
            c.capture_buffer = saved_buffer
            if type(ret1) == "dict" and dict_has(ret1, "__signal"):
                return ret1
            let saved_lines = c.pipe_lines
            let saved_index = c.pipe_index
            c.pipe_lines = pipe_output
            c.pipe_index = 0
            let ret2 = self.exec_node(node.right)
            c.pipe_lines = saved_lines
            c.pipe_index = saved_index
            return ret2

        if ntype == "Command":
            let args = self.expand_args(node.args)
            let c = self.ctx
            if c.echo_on and not node.suppress:
                let env = c.env
                let p = env.render_prompt()
                let s1 = str(node.name)
                let s2 = join(args, " ")
                let s3 = p + s1
                let s4 = s3 + " "
                let s5 = s4 + s2
                print s5
            let code = self.registry.dispatch(node.name, args)
            if type(code) == "dict" and dict_has(code, "__signal"):
                return code
            let env2 = c.env
            env2.set_errorlevel(code)
            return code

        return 0

    # ------------------------------------------------------------------ GOTO driver

    proc run_program(self, program):
        self.build_label_table(program)
        let ip = 0
        while true:
            if ip >= len(program.statements):
                let frame = self.process.pop_call()
                if frame != nil:
                    ip = frame["ip"] + 1
                    self.ctx.args = frame["args"]
                    continue
                else:
                    break
            let stmt = self.stmts[ip]
            let ret = self.exec_node(stmt)
            if type(ret) == "dict" and dict_has(ret, "__signal"):
                if ret["__signal"] == "GOTO":
                    let target = ret["target"]
                    if target == "EOF" or target == ":EOF":
                        ip = len(self.stmts)
                        continue
                    if dict_has(self.labels, target):
                        ip = self.labels[target] + 1
                        continue
                    else:
                        print "GOTO: Label not found: " + target
                        return 1
                elif ret["__signal"] == "CALL":
                    let target = ret["target"]
                    if dict_has(self.labels, target):
                        self.process.push_call("", self.ctx.args, ip)
                        self.ctx.args = ret["args"]
                        ip = self.labels[target] + 1
                        continue
                    else:
                        print "CALL: Label not found: " + target
                        return 1
                elif ret["__signal"] == "EXIT":
                    return ret["code"]
            
            ip = ip + 1
        return 0

    # ------------------------------------------------------------------ run a .BAT file

    proc run_file(self, path, args):
        let source = self.ctx.fs.read_file(path)
        let lexer  = Lexer(source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens)
        let ast    = parser.parse()
        let sub    = Interpreter(self.process)
        sub.ctx.args = args
        return sub.run_program(ast)
