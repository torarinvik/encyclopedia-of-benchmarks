# Package inventory

This package contains the bounded document-listing contract, two structurally
different references, fixed workload, provenance, and ten native ports.
All ten ports are registered in the byte-output runner and verifier.

| Language | Path |
| --- | --- |
| C | `c/m/muthukrishnan_document_listing.c` |
| C3 | `c3/m/muthukrishnan_document_listing.c3` |
| C++ | `cpp/m/muthukrishnan_document_listing.cpp` |
| Elisa | `elisa/m/muthukrishnan_document_listing.elisa` |
| Mojo | `mojo/m/muthukrishnan_document_listing.mojo` |
| Nim | `nim/m/muthukrishnan_document_listing.nim` |
| Odin | `odin/m/muthukrishnan_document_listing.odin` |
| Rust | `rust/m/muthukrishnan_document_listing.rs` |
| V | `v/m/muthukrishnan_document_listing.v` |
| Zig | `zig/m/muthukrishnan_document_listing.zig` |

Package artifacts: `README.md`, `RIGHTS.md`, `INVENTORY.md`,
`INVENTORY.json`, `workload.json`, `primary_oracle.py`,
`independent_oracle.py`, `verify_workload.py`, `check_inventory.py`, and
`__init__.py`.

The workload bounds are 67 valid input words, 68 parseable input words, 144
output bytes, and a conservative 4,096-byte native workspace cap. The static
inventory and workload helpers are present but were not run.

Each query's document IDs are serialized by increasing suffix-array rank of
their first occurrence. The RMQ traversal discovers a set of witness ranks;
the primary performs a bounded rank sort before writing, and the independent
reference gets the order from its left-to-right interval scan.
