# Package inventory

Algorithm: `factorial_last_nonzero_digit`  
ABI: `i64_array_scalar`  
Function symbol: `factorial_last_nonzero_digit`

Input is exactly `[n]`, with `0 <= n <= INT64_MAX`. The return value is the
last nonzero decimal digit of `n!`; malformed or null input returns `-1`.
The primary recurrence takes `O(log_5(n+1))` time and `O(1)` space. The
independent reference uses Dresden's base-five digit product.

Package files:

- `workload.json`: valid boundaries, a large power of five, signed-width
  boundary, and malformed-frame fixtures.
- `primary_oracle.py`: iterative divide-by-five recurrence.
- `independent_oracle.py`: base-five digit-product reference.
- `verify_workload.py`: static metadata, fixture, oracle, and port validator;
  not run.
- `README.md` and `RIGHTS.md`: contract, methods, references, and clean-room
  provenance.

Ten native ports:

- C: `c/f/factorial_last_nonzero_digit.c`
- C3: `c3/f/factorial_last_nonzero_digit.c3`
- C++: `cpp/f/factorial_last_nonzero_digit.cpp`
- Elisa: `elisa/f/factorial_last_nonzero_digit.elisa`
- Mojo: `mojo/f/factorial_last_nonzero_digit.mojo`
- Nim: `nim/f/factorial_last_nonzero_digit.nim`
- Odin: `odin/f/factorial_last_nonzero_digit.odin`
- Rust: `rust/f/factorial_last_nonzero_digit.rs`
- V: `v/f/factorial_last_nonzero_digit.v`
- Zig: `zig/f/factorial_last_nonzero_digit.zig`

Suite runner/verifier registration and root documentation are left to the
repository integrator.
