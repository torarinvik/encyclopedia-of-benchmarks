# Static package inventory

This inventory is a source-level record. The benchmark programs, workload
verifier, and static checker have not been run.

| Artifact | Purpose |
| --- | --- |
| `README.md` | Exact-rational contract, distinction from Van Eck's sequence, port map, and provenance summary |
| `RIGHTS.md` | Mathematical-source attribution and title-index discovery note |
| `workload.json` | Bounded exact-output cases and measurement profiles |
| `primary_oracle.py` | Direct digit-reversal reference |
| `independent_oracle.py` | Exact Fraction-sum reference |
| `verify_workload.py` | Optional workload/reference consistency verifier; not executed |
| `check_inventory.py` | Static artifact, export, and documentation inventory; not executed |
| Ten language files | C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig ABI ports |

The exported symbol is `van_der_corput_sequence` in every language. The ports
use `i64_array_bytes_output`, write numerator/denominator pairs as little-endian
signed 64-bit values, and reject null input before reading it.
