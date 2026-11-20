# Package inventory

Algorithm: `ulam_sequence_1_2`  
ABI: `i64_array_scalar`  
Contract: `[k]`, `1 <= k <= 14`; return U(1,2)'s kth term, otherwise `-1`.  
Maximum result: 38  
Candidate scan cap: 64  
Maximum pair-sum table index: 74  
Workspace cap: 1,024 bytes

## Native ports

- `c/u/ulam_sequence_1_2.c`
- `cpp/u/ulam_sequence_1_2.cpp`
- `rust/u/ulam_sequence_1_2.rs`
- `elisa/u/ulam_sequence_1_2.elisa`
- `c3/u/ulam_sequence_1_2.c3`
- `nim/u/ulam_sequence_1_2.nim`
- `odin/u/ulam_sequence_1_2.odin`
- `v/u/ulam_sequence_1_2.v`
- `zig/u/ulam_sequence_1_2.zig`
- `mojo/u/ulam_sequence_1_2.mojo`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

Sources: [MathWorld Ulam Sequence](https://mathworld.wolfram.com/UlamSequence.html), [OEIS A002858](https://oeis.org/A002858), and the pinned [RosettaCodeData title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks). RosettaCodeData is discovery-only.

Title-band exclusions/crosswalk: `padovan_sequence`, `multiplicative_order`, `cipolla_modular_square_root`, and `problem41` cover the Padovan, multiplicative-order, Cipolla, and Pandigital Prime titles. `hamming_numbers` covers 5-smooth numbers only; generalized smoothness remains a broader contract and is not marked a duplicate. Ulam spiral is a visualization, distinct from U(1,2).
