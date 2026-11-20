# Package inventory

- Algorithm: `brzozowski_dfa_to_regex`
- ABI: `i64_array_bytes_output`
- Maximum valid input: 9 signed 64-bit words
- Maximum parseable input: 10 signed 64-bit words
- Maximum output: 270 raw ASCII bytes
- Fixed workspace cap: 16,384 bytes
- Discovery lead: pinned RosettaCodeData title index, score 16, line 1608

| Language | Native source |
| --- | --- |
| C | `c/b/brzozowski_dfa_to_regex.c` |
| C3 | `c3/b/brzozowski_dfa_to_regex.c3` |
| C++ | `cpp/b/brzozowski_dfa_to_regex.cpp` |
| Elisa | `elisa/b/brzozowski_dfa_to_regex.elisa` |
| Mojo | `mojo/b/brzozowski_dfa_to_regex.mojo` |
| Nim | `nim/b/brzozowski_dfa_to_regex.nim` |
| Odin | `odin/b/brzozowski_dfa_to_regex.odin` |
| Rust | `rust/b/brzozowski_dfa_to_regex.rs` |
| V | `v/b/brzozowski_dfa_to_regex.v` |
| Zig | `zig/b/brzozowski_dfa_to_regex.zig` |

Package-local support sources are `primary_oracle.py`, `independent_oracle.py`,
`workload.json`, `verify_workload.py`, and `check_inventory.py`. The package is
registered with the `i64_array_bytes_output` runner and verifier, including
generated capacity, null-pointer, and malformed-input ABI probes; README,
catalog, and shared coverage-ledger entries are integrated. Sources and
validation helpers have not been executed or compiled.
