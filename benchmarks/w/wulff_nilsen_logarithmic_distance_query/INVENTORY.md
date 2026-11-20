# Package inventory

Algorithm: `wulff_nilsen_logarithmic_distance_query`

- Suite ABI: `i64_array_bytes_output`
- Symbol: `wulff_nilsen_logarithmic_distance_query`
- `k=16`, `n<=8`, `m<=28`, `q<=32`
- Maximum valid input: 166 signed-i64 words; parser ceiling: 167 words
- Maximum output: 520 bytes
- Workspace cap: 16,384 bytes
- Widest 64-bit fixed arrays plus hierarchy masks and staged output: 14,216 bytes; up to four tree-build recursive frames occur before staged output allocation.
- Primary reference: `benchmarks/wulff_nilsen_logarithmic_distance_query_oracle.py`
- Independent reference: `benchmarks/wulff_nilsen_logarithmic_distance_query_verifier_oracle.py`
- Workload: `workload.json`
- Package documentation: `README.md`, `RIGHTS.md`

| Language | Source |
|---|---|
| C | `c/w/wulff_nilsen_logarithmic_distance_query.c` |
| C3 | `c3/w/wulff_nilsen_logarithmic_distance_query.c3` |
| C++ | `cpp/w/wulff_nilsen_logarithmic_distance_query.cpp` |
| Elisa | `elisa/w/wulff_nilsen_logarithmic_distance_query.elisa` |
| Mojo | `mojo/w/wulff_nilsen_logarithmic_distance_query.mojo` |
| Nim | `nim/w/wulff_nilsen_logarithmic_distance_query.nim` |
| Odin | `odin/w/wulff_nilsen_logarithmic_distance_query.odin` |
| Rust | `rust/w/wulff_nilsen_logarithmic_distance_query.rs` |
| V | `v/w/wulff_nilsen_logarithmic_distance_query.v` |
| Zig | `zig/w/wulff_nilsen_logarithmic_distance_query.zig` |

Static package checks have not been run.
