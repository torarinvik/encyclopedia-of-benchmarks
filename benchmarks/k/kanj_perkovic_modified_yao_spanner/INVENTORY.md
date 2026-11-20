# Package inventory

Algorithm: `kanj_perkovic_modified_yao_spanner` (Encyclopedia of Algorithms,
Chapter 294), fixed `k=14` modified-Yao edge-selection pass.

- ABI: `i64_array_scalar`; input limit 312 valid words, 313 parseable words.
- Output: signed-i64 mutual-selection edge mask; `-1` for invalid input.
- Workspace cap: 16,384 bytes.
- Widest 64-bit-index layout accounts for 9,660 raw array bytes before
  alignment and scalar locals; the cap leaves remaining headroom for them.
- Primary source: Kanj and Perković, §2.3, Figure 3, DOI
  `10.4230/LIPIcs.STACS.2008.1320`.
- Independent reference: direct cyclic-rotation scans in
  `independent_oracle.py`.
- Primary reference: cone-bucket pass in `primary_oracle.py`.
- Static workload reconciliation: `verify_workload.py`.
- Static source inventory: `check_inventory.py` and `INVENTORY.json`.

| Language | Source |
|---|---|
| C | `c/k/kanj_perkovic_modified_yao_spanner.c` |
| C3 | `c3/k/kanj_perkovic_modified_yao_spanner.c3` |
| C++ | `cpp/k/kanj_perkovic_modified_yao_spanner.cpp` |
| Elisa | `elisa/k/kanj_perkovic_modified_yao_spanner.elisa` |
| Mojo | `mojo/k/kanj_perkovic_modified_yao_spanner.mojo` |
| Nim | `nim/k/kanj_perkovic_modified_yao_spanner.nim` |
| Odin | `odin/k/kanj_perkovic_modified_yao_spanner.odin` |
| Rust | `rust/k/kanj_perkovic_modified_yao_spanner.rs` |
| V | `v/k/kanj_perkovic_modified_yao_spanner.v` |
| Zig | `zig/k/kanj_perkovic_modified_yao_spanner.zig` |

The shared scalar runner, verifier, README, catalog, and Encyclopedia Chapter
294 crosswalk are integrated.
All review is static; no program, test, helper, checker, compiler, or benchmark
has been run.
