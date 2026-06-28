# test_int21.sage — Test MS-DOS Interrupt 21h emulation
import std.testing
from int21 import Int21Handler

let t = std.testing

class MockIO:
    proc init(self):
        self.prints = []
        self.chars = []
        self.reads = ["Y"]

    proc print_string(self, text):
        self.prints.push(text)
        
    proc print_char(self, ch):
        self.chars.push(ch)
        
    proc read_char(self):
        return self.reads.pop()

class MockKernel:
    proc init(self):
        self.io = MockIO()
        self.running = true

proc test_int21_exit():
    let kernel = MockKernel()
    let int21 = Int21Handler(kernel)
    
    # AH=4Ch (sys_exit)
    let ret = int21.call(0x4C, 0, 0, 0, 0, 0, 0)
    t.assert_eq(ret, 0, "sys_exit returns 0")
    t.assert_eq(kernel.running, false, "sys_exit halts kernel")
    t.assert_eq(kernel.io.prints[0], "Process terminated with code: 0\n", "sys_exit prints message")

proc test_int21_print():
    let kernel = MockKernel()
    let int21 = Int21Handler(kernel)
    
    # AH=09h (sys_print_string), DX="Hello DOS"
    int21.call(0x09, 0, 0, 0, "Hello DOS", 0, 0)
    t.assert_eq(kernel.io.prints[0], "Hello DOS", "sys_print_string outputs correctly")

proc test_int21_char_io():
    let kernel = MockKernel()
    let int21 = Int21Handler(kernel)
    
    # AH=01h (sys_char_input)
    let ch = int21.call(0x01, 0, 0, 0, 0, 0, 0)
    t.assert_eq(ch, "Y", "sys_char_input reads character")
    t.assert_eq(kernel.io.chars[0], "Y", "sys_char_input echoes character")
    
    # AH=02h (sys_char_output), DX="X"
    int21.call(0x02, 0, 0, 0, "X", 0, 0)
    t.assert_eq(kernel.io.chars[1], "X", "sys_char_output prints character")

test_int21_exit()
test_int21_print()
test_int21_char_io()

print "int21 tests passed."
