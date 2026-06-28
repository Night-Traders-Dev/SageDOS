# int21.sage — MS-DOS API Interrupt Handler
# Implements the INT 21h system calls that DOS programs rely on.

class Int21Handler:
    proc init(self, kernel):
        self.kernel = kernel
        
    proc call(self, ah, al, bx, cx, dx, si, di):
        # Dispatch table for MS-DOS interrupts
        if ah == 0x01: return self.sys_char_input()
        if ah == 0x02: return self.sys_char_output(dx)
        if ah == 0x09: return self.sys_print_string(dx)
        if ah == 0x4C: return self.sys_exit(al)
        
        # ... more to be implemented
        return 0

    proc sys_char_input(self):
        # Simulates AH=01h (Read character from STDIN with echo)
        let ch = self.kernel.io.read_char()
        self.kernel.io.print_char(ch)
        return ch

    proc sys_char_output(self, dx):
        # Simulates AH=02h (Write character to STDOUT)
        self.kernel.io.print_char(dx)
        return 0

    proc sys_print_string(self, dx):
        # Simulates AH=09h (Output character string)
        # Note: In real DOS, dx points to a '$' terminated string in memory.
        # Here we just pass a string reference.
        self.kernel.io.print_string(dx)
        return 0

    proc sys_exit(self, return_code):
        # Simulates AH=4Ch (Terminate process with return code)
        self.kernel.io.print_string("Process terminated with code: " + str(return_code) + "\n")
        self.kernel.running = false
        return 0
