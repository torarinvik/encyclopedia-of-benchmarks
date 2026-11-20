# Package inventory

| Language | Native port |
|---|---|
| C | `c/b/batch_gcd_small_range_precomputed.c` |
| C3 | `c3/b/batch_gcd_small_range_precomputed.c3` |
| C++ | `cpp/b/batch_gcd_small_range_precomputed.cpp` |
| Elisa | `elisa/b/batch_gcd_small_range_precomputed.elisa` |
| Mojo | `mojo/b/batch_gcd_small_range_precomputed.mojo` |
| Nim | `nim/b/batch_gcd_small_range_precomputed.nim` |
| Odin | `odin/b/batch_gcd_small_range_precomputed.odin` |
| Rust | `rust/b/batch_gcd_small_range_precomputed.rs` |
| V | `v/b/batch_gcd_small_range_precomputed.v` |
| Zig | `zig/b/batch_gcd_small_range_precomputed.zig` |

| Artifact | Purpose |
|---|---|
| `primary_oracle.py` | Linear SPF sieve, factor triples, triangular GCD lookup, and bounded batch evaluation |
| `independent_oracle.py` | Direct Euclidean GCD for each query pair |
| `workload.json` | ABI, limits, provenance, and hand-authored fixtures |
| `verify_workload.py` | Static fixture, metadata, rights, and port-path inventory |
| `RESERVATION.md` | Original shared-inventory reservation and local-overlap review; replace with implementation status during integration |
