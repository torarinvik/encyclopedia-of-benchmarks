# Static inventory

ABI: `i64_array_scalar`  
Exported symbol: `josephus_batched_small_k`  
Input: exactly `[N,K]`, with `1 <= N <= 1,000,000` and `1 <= K <= 32`.  
Output: zero-based surviving participant, or `-1` for invalid input.  
Workspace cap: 16,384 bytes; primary frame storage is 1,024 i64 values (8,192 bytes).

| Language | Source |
|---|---|
| C | `c/j/josephus_batched_small_k.c` |
| C3 | `c3/j/josephus_batched_small_k.c3` |
| C++ | `cpp/j/josephus_batched_small_k.cpp` |
| Elisa | `elisa/j/josephus_batched_small_k.elisa` |
| Mojo | `mojo/j/josephus_batched_small_k.mojo` |
| Nim | `nim/j/josephus_batched_small_k.nim` |
| Odin | `odin/j/josephus_batched_small_k.odin` |
| Rust | `rust/j/josephus_batched_small_k.rs` |
| V | `v/j/josephus_batched_small_k.v` |
| Zig | `zig/j/josephus_batched_small_k.zig` |

The workload, primary recurrence reference, independent linear reference, tiny list simulator, rights note, and static inventory artifacts are in this directory. No suite runner or global catalog integration is included here.
