# Package inventory

Algorithm: `random_permutation_cycle_cap_count`  
ABI: `i64_array_scalar`  
Function symbol: `random_permutation_cycle_cap_count`

Input is exactly `[n,k]`, with `1 <= n <= 20` and `1 <= k <= n`. The result
is the exact number of permutations of `n` labels whose cycles are all at
most `k` long. Invalid or null input returns `-1`. The maximum valid result
is `20! = 2,432,902,008,176,640,000`, which fits signed 64-bit arithmetic.

Package-local files:

- `workload.json`: valid boundary and malformed-frame fixtures, source title,
  score, and provenance metadata.
- `primary_oracle.py`: fixed-label cycle recurrence.
- `independent_oracle.py`: integer cycle-type partition enumeration.
- `verify_workload.py`: static source validator; not run.
- `README.md` and `RIGHTS.md`: method, complexity, references, rights, and
  clean-room provenance.

Ten native ports are present:

- C: `c/r/random_permutation_cycle_cap_count.c`
- C3: `c3/r/random_permutation_cycle_cap_count.c3`
- C++: `cpp/r/random_permutation_cycle_cap_count.cpp`
- Elisa: `elisa/r/random_permutation_cycle_cap_count.elisa`
- Mojo: `mojo/r/random_permutation_cycle_cap_count.mojo`
- Nim: `nim/r/random_permutation_cycle_cap_count.nim`
- Odin: `odin/r/random_permutation_cycle_cap_count.odin`
- Rust: `rust/r/random_permutation_cycle_cap_count.rs`
- V: `v/r/random_permutation_cycle_cap_count.v`
- Zig: `zig/r/random_permutation_cycle_cap_count.zig`

Suite runner/verifier registration and root documentation are left to the
repository integrator.
