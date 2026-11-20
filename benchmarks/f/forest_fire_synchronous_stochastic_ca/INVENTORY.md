# Package inventory

The static inventory is [`inventory.json`](inventory.json). The package-local
`check_inventory.py` checks declared paths, symbols, and bounds without loading
or calling a native port. `verify_workload.py` compares the pinned workload
with both references; it is included as source only and has not been run.

Ten native source ports are declared: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust,
V, and Zig. The two references use direct per-cell neighbor checks and a
separate burning-neighbor-mask pass. Both require and preserve an empty outer
boundary. The fixed workspace cap is 192 bytes,
covering the largest 152-byte combination of fixed board/count arrays plus
scalar and alignment margin. The maximum valid frame is 1094 i64 words; the
maximum output is 89 i64 words / 712 bytes.

No programs, tests, scripts, helpers, checkers, builds, compilers, profilers,
or benchmarks were run.
