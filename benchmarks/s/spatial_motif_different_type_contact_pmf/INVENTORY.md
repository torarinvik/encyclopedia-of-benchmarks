# Package inventory

Algorithm: `spatial_motif_different_type_contact_pmf`

ABI: `i64_array_bytes_output`

Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.

References: `primary_oracle.py` (three-category multinomial marginal),
`independent_oracle.py` (unique multiset permutation enumeration).

Bounded input: exactly five i64 words, `1<=L<=10`, and each sequence's X/Y
counts sum to at most L. Maximum output is 120 bytes; maximum workspace is
1,024 bytes.

Metadata: `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`,
`workload.json`, `primary_oracle.py`, `independent_oracle.py`,
`check_inventory.py`.

All ten language ports and package metadata are present. The package is
registered with the shared byte-output runner and verifier; the global
catalog integration is owned by the parent task.
