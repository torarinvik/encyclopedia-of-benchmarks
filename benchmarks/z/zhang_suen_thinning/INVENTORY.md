# Static inventory

Package: `zhang_suen_thinning`  
ABI: `i64_array_bytes_output`  
Exported symbol: `zhang_suen_thinning`  
Input: `[rows, columns, row-major binary pixels...]`; dimensions 1–32, exact
frame length, and pixel values 0 or 1. Pixels on the image border are immutable.  
Maximum valid input: 1,026 signed-i64 words; parser limit: 1,027 words.  
Output: one byte per final binary pixel in row-major order; maximum 1,024 bytes.  
Workspace metadata: 2,048 bytes for the image and phase-mark arrays.  
Algorithm: Zhang-Suen iterative thinning with simultaneous candidate marking
in two ordered directional subiterations.  
Primary reference: flat image and marker arrays. Independent reference:
immutable row tuples rebuilt after each subiteration.  
Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.  
`i64_array_bytes_output` runner/verifier and root catalog integration are
registered.

This inventory records source presence and contract fields only. It has not
been executed.
