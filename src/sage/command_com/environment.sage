# environment.sage — DOS-like environment block
# Phase 4: Manages PATH, TEMP, PROMPT, COMSPEC, ERRORLEVEL,
#          current directory, search paths, and process state.

import sys

class Environment:
    proc init(self):
        let d = {}
        self.vars        = d    # string → string
        self.errorlevel  = 0
        self.cwd         = "/"  # current working directory
        let arr = []
        self.dir_stack   = arr
        let arr2 = []
        self.setlocal_stack = arr2
        self.delayed_expansion = false
        self._init_defaults()

    proc _init_defaults(self):
        let p1 = sys.getenv("PATH")
        let k_path = "PATH"
        self.vars[k_path] = p1
        
        let p2 = sys.getenv("TEMP")
        let k_temp = "TEMP"
        self.vars[k_temp] = p2
        
        let v1 = "BATCH.SAGE"
        let k_comspec = "COMSPEC"
        self.vars[k_comspec] = v1
        
        let v2 = "$P$G"
        let k_prompt = "PROMPT"
        self.vars[k_prompt] = v2
        
        let v3 = ".BAT;.SAG;.EXE;.COM"
        let k_pathext = "PATHEXT"
        self.vars[k_pathext] = v3

    proc set_var(self, name, value):
        let uname = upper(name)
        let v = self.vars
        v[uname] = value

    proc get_var(self, name):
        let uname = upper(name)
        let v = self.vars
        if dict_has(v, uname):
            return v[uname]
        return ""

    proc del_var(self, name):
        let uname = upper(name)
        let v = self.vars
        dict_delete(v, uname)



    proc set_errorlevel(self, level):
        self.errorlevel = level
        let s = str(level)
        let v = self.vars
        v["ERRORLEVEL"] = s

    proc get_errorlevel(self):
        return self.errorlevel

    proc chdir(self, path):
        self.cwd = path
        let v = self.vars
        v["CD"] = path

    proc render_prompt(self):
        let p = self.get_var("PROMPT")
        let c = self.cwd
        p = replace(p, "$P", c)
        p = replace(p, "$G", ">")
        p = replace(p, "$L", "<")
        p = replace(p, "$N", "C")
        p = replace(p, "$Q", "=")
        p = replace(p, "$$", "$")
        return p

    proc setlocal(self, flag):
        let snapshot = {}
        for k in dict_keys(self.vars):
            snapshot[k] = self.vars[k]
        
        let frame = {}
        frame["vars"] = snapshot
        frame["cwd"] = self.cwd
        frame["delayed_expansion"] = self.delayed_expansion
        push(self.setlocal_stack, frame)
        
        if flag == "ENABLEDELAYEDEXPANSION":
            self.delayed_expansion = true
        elif flag == "DISABLEDELAYEDEXPANSION":
            self.delayed_expansion = false

    proc endlocal(self):
        if len(self.setlocal_stack) > 0:
            let frame = pop(self.setlocal_stack)
            self.vars = frame["vars"]
            self.cwd = frame["cwd"]
            self.delayed_expansion = frame["delayed_expansion"]
