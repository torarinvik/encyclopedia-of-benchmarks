# Package inventory

- Algorithm: `magic_square_doubly_even_complement`
- ABI: `scalar_call`
- Native ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig
- Primary reference: `primary_oracle.py` (direct diagonal-residue construction)
- Independent reference: `independent_oracle.py` (four-row complement mask plus normal-square invariants)
- Workload: `workload.json`
- Rights and provenance: `RIGHTS.md`
- Static inventory helper: `check_inventory.py`

The package files record the Rosetta Code discovery and the distinction from local odd-order Siamese and singly-even Strachey magic-square profiles. The native implementations generate cells directly and use zero scratch bytes. Shared `scalar_call` runner/verifier and catalog registration are integrated.
