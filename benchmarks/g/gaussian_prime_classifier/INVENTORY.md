# Static package inventory

- Algorithm: `gaussian_prime_classifier`
- ABI: `i64_array_scalar`
- Native implementations: ten, one in each supported language.
- Input: exactly two signed i64 coordinates in `[-10000,10000]`.
- Maximum norm: 200,000,000; all accepted arithmetic fits signed i64.
- Declared native workspace: 128 bytes of fixed scalar state.
- References: classification plus trial division; classification plus a
  bounded rational-prime sieve.
- Workload covers zero, units, axis and norm classifications, signs, accepted
  bounds, malformed frames, coordinate overflow probes, and null input.

## Native paths

- `c/g/gaussian_prime_classifier.c`
- `c3/g/gaussian_prime_classifier.c3`
- `cpp/g/gaussian_prime_classifier.cpp`
- `elisa/g/gaussian_prime_classifier.elisa`
- `mojo/g/gaussian_prime_classifier.mojo`
- `nim/g/gaussian_prime_classifier.nim`
- `odin/g/gaussian_prime_classifier.odin`
- `rust/g/gaussian_prime_classifier.rs`
- `v/g/gaussian_prime_classifier.v`
- `zig/g/gaussian_prime_classifier.zig`

## Package-local files

- `__init__.py`
- `README.md`
- `RIGHTS.md`
- `INVENTORY.md`
- `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`
- `independent_oracle.py`
- `verify_workload.py`
- `check_inventory.py`

The static inventory and workload reconciliation helpers are source artifacts
and have not been executed.
