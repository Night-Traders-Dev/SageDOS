from token       import TOK_VARIABLE, TOK_STRING, TOK_WORD
import io

class CommandContext:
    proc init(self, env, varstore, fs, batch_args):
        self.env            = env
        self.vars           = varstore
        self.fs             = fs
        self.args           = batch_args    # %0..%9
        self.echo_on        = true
        self.stdout         = nil           # nil = real stdout
        self.stderr         = nil
        self.capture_mode   = false         # true = stdout → capture_buffer
        let cap = []
        self.capture_buffer = cap
        self.pipe_lines     = nil           # lines for piped stdin
        self.pipe_index     = 0

    proc expand_token(self, tok):
        if tok.kind == TOK_VARIABLE:
            if tok.is_delayed:
                if self.env.delayed_expansion:
                    return self.vars.get(tok.value)
                else:
                    return "!" + tok.value + "!"
            else:
                return self.vars.get(tok.value)
        if tok.kind == TOK_STRING or tok.kind == TOK_WORD:
            return self.vars.expand(tok.value)
        return str(tok.value)

    proc shift_args(self):
        if len(self.args) > 0:
            self.args = slice(self.args, 1, len(self.args))
            
            # Update env.vars %1 through %9
            let i = 1
            while i < 10:
                if i - 1 < len(self.args):
                    self.env.set_var(str(i), self.args[i - 1])
                else:
                    self.env.set_var(str(i), "")
                i = i + 1

    proc get_arg(self, n):
        if n < len(self.args):
            return self.args[n]
        return ""

    proc write_out(self, text):
        if self.capture_mode:
            push(self.capture_buffer, text)
        elif self.stdout != nil:
            self.fs.append_file(self.stdout, text + "\n")
        else:
            print text

    proc read_line(self):
        if self.pipe_lines != nil and self.pipe_index < len(self.pipe_lines):
            let line = self.pipe_lines[self.pipe_index]
            self.pipe_index = self.pipe_index + 1
            return line
        return input()
