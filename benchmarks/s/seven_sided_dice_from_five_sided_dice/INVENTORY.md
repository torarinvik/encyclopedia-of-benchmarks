# Static inventory

Package: `seven_sided_dice_from_five_sided_dice`  
ABI: `i64_array_bytes_output`  
Exported symbol: `seven_sided_dice_from_five_sided_dice`  
Input: `[draw_count, d0, ..., d(draw_count-1)]`, at most 256 independent
five-sided-die digits, each encoded as 0–4.  
Maximum valid input: 257 signed-i64 words; parser limit: 258 words.  
Output: one unsigned byte per face, each in 1–7; maximum 256 bytes.  
Algorithm: base-5 reservoir with quotient entropy reuse and rejected-tail
recycling; unused final entropy is discarded on finite-tape exhaustion.  
Primary reference: scalar reservoir state machine. Independent reference:
interval bucket decomposition using quotient and remainder.  
Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.  
`i64_array_bytes_output` runner/verifier and root catalog integration are
registered.

This inventory is static. No checker, executable, compiler, or test has been
run.
