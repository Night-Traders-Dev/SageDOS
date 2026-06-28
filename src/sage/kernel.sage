# kernel.sage — SageDOS Kernel (MSDOS.SYS equivalent)
# This module initializes the core OS structures and provides the central
# dispatcher for system calls.

from int21 import Int21Handler
import sys
from main import CommandCom
from process import BatchProcess

class SageDOSKernel:
    proc init(self, io_layer):
        self.io = io_layer
        self.int21 = Int21Handler(self)
        self.running = false
        self.process_table = []
        
    proc boot(self):
        self.io.print_string("\nStarting SageDOS...\n")
        self.running = true
        
        # In a real DOS, we would load COMMAND.COM here.
        # For now, we will simulate dropping into a shell.
        self.execute_shell()

    proc execute_shell(self):
        self.io.print_string("Loading COMMAND.COM (SageBatch)...\n")
        
        let shell = CommandCom()
        let proc_inst = BatchProcess("INTERACTIVE", [])
        shell.run(proc_inst)
                
    proc shutdown(self):
        self.io.print_string("System halted.\n")
        self.running = false
