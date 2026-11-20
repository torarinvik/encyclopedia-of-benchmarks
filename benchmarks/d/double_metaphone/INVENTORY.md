# Static package inventory

| Role | File |
|---|---|
| State-object primary reference | `primary_oracle.py` |
| Rule-action independent reference | `independent_oracle.py` |
| Bounds, byte framing, outputs, and fresh fixtures | `workload.json` |
| Algorithm profile and contract | `README.md` |
| Source and license record | `RIGHTS.md` |
| Static source manifest | `INVENTORY.md` |

| Language | Port |
|---|---|
| C | `c/d/double_metaphone.c` |
| C3 | `c3/d/double_metaphone.c3` |
| C++ | `cpp/d/double_metaphone.cpp` |
| Elisa | `elisa/d/double_metaphone.elisa` |
| Mojo | `mojo/d/double_metaphone.mojo` |
| Nim | `nim/d/double_metaphone.nim` |
| Odin | `odin/d/double_metaphone.odin` |
| Rust | `rust/d/double_metaphone.rs` |
| V | `v/d/double_metaphone.v` |
| Zig | `zig/d/double_metaphone.zig` |

## Static rule-family coverage

The ports include the initial silent-prefix and X rules; the vowel, duplicate,
and ordinary consonant rules; the full context branches for C, D, G, J, L, R,
S, T, W, X, and Z; the `Ç` and `Ñ` cases; and the four-symbol dual-key
termination and serialization rules. Inputs are normalized and checked before
capacity handling. No programs, checks, or compiler actions have been run.
