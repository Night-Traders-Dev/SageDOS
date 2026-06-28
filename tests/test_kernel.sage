# test_kernel.sage — Test the SageDOS kernel
import std.testing
from kernel import SageDOSKernel

let t = std.testing

class MockIO:
    proc init(self):
        self.prints = []

    proc print_string(self, text):
        self.prints.push(text)

proc test_kernel_init():
    let io = MockIO()
    let kernel = SageDOSKernel()
    kernel.init(io)
    
    t.assert_eq(kernel.running, false, "Kernel is not running initially")
    # Don't boot it fully because it drops into REPL, just verify properties
    t.assert_eq(kernel.int21 != null, true, "Int21 dispatcher is bound")

test_kernel_init()
print "kernel tests passed."
