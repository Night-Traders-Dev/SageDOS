# boot.sage — System Bootloader
# This is the main entry point for SageDOS. It initializes the BIOS layer,
# loads the Kernel, and hands over control.

from bios_io import BIOSLayer
from kernel import SageDOSKernel

proc main():
    # Phase 1: Initialize hardware abstraction (IO.SYS)
    let bios = BIOSLayer()
    
    # Phase 2: Load and initialize the kernel (MSDOS.SYS)
    let kernel = SageDOSKernel(bios)
    
    # Phase 3: Boot the system
    kernel.boot()

main()
