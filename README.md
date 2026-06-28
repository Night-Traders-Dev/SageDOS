# SageDOS

> A clean-room MS-DOS 4.0 clone implemented entirely in [SageLang](https://github.com/Night-Traders-Dev/SageLang), running on [SageVM](https://github.com/Night-Traders-Dev/SageVM) or native C.

SageDOS is a faithful, modular reimplementation of the classic MS-DOS kernel (`MSDOS.SYS` and `IO.SYS` layers) written in pure Sage. It is designed to provide the core services—file system, memory management, and process control—expected by a DOS command processor like [SageBatch](https://github.com/Night-Traders-Dev/SageBatch).

## Architecture

In MS-DOS, the system is split into three main layers:
1. **BIOS (`IO.SYS`)**: Hardware-specific I/O drivers.
2. **DOS (`MSDOS.SYS`)**: High-level OS services (INT 21h).
3. **Shell (`COMMAND.COM`)**: The user interface.

In SageDOS, we map these layers to SageLang modules:
1. **HAL (`hal.sage`)**: Hardware Abstraction Layer. In hosted mode, this translates hardware requests to OS system calls. In bare-metal mode, this interacts directly with hardware.
2. **Kernel (`kernel.sage`)**: The core OS services. Provides file system management (FAT32/VFS), memory allocation, and process management.
3. **Shell**: `SageBatch` will be integrated as the default command processor.

## Repository Layout

```
SageDOS/
├── src/
│   ├── bios/          # Hardware Abstraction Layer (IO.SYS equivalent)
│   ├── dos/           # Kernel services (MSDOS.SYS equivalent)
│   └── boot/          # Bootloader stubs
├── ref/
│   └── MS-DOS/        # Reference source code (v4.0)
└── README.md
```

## DOS Compatibility

SageDOS aims to emulate the MS-DOS 4.0 API (INT 21h services). While it doesn't execute real 16-bit x86 binaries (unless combined with a CPU emulator), it provides the exact same API surface in SageLang for native Sage programs to interface with.

- **INT 21h**: System Calls (File I/O, Process, Memory)
- **FAT File System**: Virtual or real FAT file system driver
