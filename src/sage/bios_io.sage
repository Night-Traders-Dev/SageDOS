# io.sage — Hardware Abstraction Layer (IO.SYS equivalent)
# This module abstracts the underlying host environment (SageVM or Native)
# and exposes basic I/O primitives to the DOS kernel.

import sys

class BIOSLayer:
    proc init(self):
        return

    proc print_string(self, text):
        print text

    proc print_char(self, ch):
        print ch # Print with newline for now in basic SageLang

    proc read_char(self):
        # In a real BIOS, this would invoke INT 16h AH=00h.
        return ""

    proc read_line(self, prompt):
        return input(prompt)
