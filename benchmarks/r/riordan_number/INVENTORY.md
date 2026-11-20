# Static inventory

Algorithm: `riordan_number`  
ABI: `i64_array_scalar`  
Valid input: `[n]`, `0<=n<=30`  
Parseable input cap: 2 words  
Output: exact Riordan number `R_n`, or `-1` for invalid input  
Maximum output: `439,742,222,071` at `n=30`  
Primary table: 31 i64 entries (248 bytes)  
Workspace cap: 512 bytes

The local duplicate audit found the related `motzkin_number` package, which
counts all nonnegative Motzkin excursions. This package counts the strict
subset with no flat steps at ground level, so the sequence and path language
are distinct. No local `Riordan`/A005043 package or matching output profile was
found.

| Language | Path | Exported symbol |
| --- | --- | --- |
| C | `c/r/riordan_number.c` | `riordan_number` |
| C3 | `c3/r/riordan_number.c3` | `riordan_number` |
| C++ | `cpp/r/riordan_number.cpp` | `riordan_number` |
| Elisa | `elisa/r/riordan_number.elisa` | `riordan_number` |
| Mojo | `mojo/r/riordan_number.mojo` | `riordan_number` |
| Nim | `nim/r/riordan_number.nim` | `riordan_number` |
| Odin | `odin/r/riordan_number.odin` | `riordan_number` |
| Rust | `rust/r/riordan_number.rs` | `riordan_number` |
| V | `v/r/riordan_number.v` | `riordan_number` |
| Zig | `zig/r/riordan_number.zig` | `riordan_number` |

The shared `i64_array_scalar` runner and verifier register this package. The
package contains bounded fixtures, separate recurrence and trinomial
references, provenance/rights, static inventory, and package metadata. This
is a source-only inventory; no port or helper was executed.
