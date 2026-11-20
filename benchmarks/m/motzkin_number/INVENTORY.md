# Static inventory

Algorithm: `motzkin_number`  
ABI: `i64_array_scalar`  
Valid input: `[n]`, `0<=n<=30`  
Parseable input cap: 2 words  
Output: exact Motzkin number `M_n`, or `-1` for invalid input  
Maximum output: `1,697,385,471,211` at `n=30`  
Primary table: 31 i64 entries (248 bytes)  
Workspace cap: 512 bytes

Reservation cross-check: the root agent approved this package after checking
local coverage; `book_next_gap` confirmed its active Chapter 331 matching
package does not overlap Motzkin or Riordan numbers. The package search also
found no divisor-count-prime reservation, and `codewars_nist_gap` confirmed no
overlap with its active package.

RosettaCodeData 44–42 title crosswalk: Motzkin numbers were absent and are
implemented here. Riordan numbers are implemented separately in
`benchmarks/r/riordan_number/`; their paths prohibit horizontal steps at
ground level. The “numbers whose count of divisors is prime” title has
no exact local profile; local divisor-count functions and primality checks
cover component operations only. The title index also maps Perlin noise,
point-in-polygon ray casting, Ramer–Douglas–Peucker simplification,
Tonelli–Shanks, subset-sum variants, weird numbers, integer partitions, and
maze-solving to existing packages. Other titles that need a tighter
algorithm/output contract remain outside this package.

| Language | Path | Exported symbol |
| --- | --- | --- |
| C | `c/m/motzkin_number.c` | `motzkin_number` |
| C3 | `c3/m/motzkin_number.c3` | `motzkin_number` |
| C++ | `cpp/m/motzkin_number.cpp` | `motzkin_number` |
| Elisa | `elisa/m/motzkin_number.elisa` | `motzkin_number` |
| Mojo | `mojo/m/motzkin_number.mojo` | `motzkin_number` |
| Nim | `nim/m/motzkin_number.nim` | `motzkin_number` |
| Odin | `odin/m/motzkin_number.odin` | `motzkin_number` |
| Rust | `rust/m/motzkin_number.rs` | `motzkin_number` |
| V | `v/m/motzkin_number.v` | `motzkin_number` |
| Zig | `zig/m/motzkin_number.zig` | `motzkin_number` |

The shared `i64_array_scalar` runner and verifier register this package. The
package also contains `workload.json`, `primary_oracle.py`,
`independent_oracle.py`, `verify_workload.py`, `check_inventory.py`, and
`RIGHTS.md`. This is a source-only inventory; no port or helper was executed.
