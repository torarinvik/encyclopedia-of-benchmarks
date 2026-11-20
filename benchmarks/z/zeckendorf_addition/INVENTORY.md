# Package inventory

Algorithm: `zeckendorf_addition`  
ABI: `i64_array_bytes_output`  
Input: `[len_a,bits_a...,len_b,bits_b...]`, canonical MSB-first vectors, each
1..64 digits; zero is `[0]`.  
Frame bounds: 130 valid words, 131 parseable; oversized vectors are rejected
without truncation.  
Output: canonical high-weight-first ASCII bits; maximum 66 bytes.  
No truncation; 64-bit input-vector sums are below `2^46`.  
Workspace cap: 256 bytes, including one 66-byte digit vector and bounded
local state.  
References: three-pass normalization and independent Fibonacci-weight
decode/greedy encode.

## Ten native source ports

- `c/z/zeckendorf_addition.c`
- `cpp/z/zeckendorf_addition.cpp`
- `rust/z/zeckendorf_addition.rs`
- `elisa/z/zeckendorf_addition.elisa`
- `c3/z/zeckendorf_addition.c3`
- `nim/z/zeckendorf_addition.nim`
- `odin/z/zeckendorf_addition.odin`
- `v/z/zeckendorf_addition.v`
- `zig/z/zeckendorf_addition.zig`
- `mojo/z/zeckendorf_addition.mojo`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

Sources: [Ahlbach et al. (2013), journal PDF](https://www.fq.math.ca/Papers1/51-3/AhlbachUsatineFrougnyPippenger.pdf),
[DOI](https://doi.org/10.1080/00150517.2013.12427944), and the pinned
[RosettaCodeData title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
for discovery only.
