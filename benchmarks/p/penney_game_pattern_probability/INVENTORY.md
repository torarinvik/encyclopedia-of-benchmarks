# Package inventory

Algorithm: `penney_game_pattern_probability`  
ABI: `i64_array_scalar`  
Function symbol: `penney_game_pattern_probability`

The input is exactly `[L, A_mask, B_mask]`, where `1 <= L <= 4`, the masks are distinct values in `[0, 2^L)`, and each mask is read as an `L`-bit word from most-significant bit to least-significant bit. The result is the exact probability that A first appears before B in an independent fair-coin stream, reduced modulo `998244353`; invalid or null input returns `-1`.

Package-local artifacts:

- `workload.json`: bounded valid cases, malformed frames, invalid values, null input, and public-title provenance.
- `primary_oracle.py`: proper-prefix automaton and modular linear solve.
- `independent_oracle.py`: all short binary suffix states and an exact-rational linear solve.
- `verify_workload.py`: static metadata, fixture-frame, reference, documentation, and port-presence validator; not run.
- `README.md` and `RIGHTS.md`: method, complexity, clean-room status, and attribution.

Ten native ports are present: `c/p/penney_game_pattern_probability.c`, `c3/p/penney_game_pattern_probability.c3`, `cpp/p/penney_game_pattern_probability.cpp`, `elisa/p/penney_game_pattern_probability.elisa`, `mojo/p/penney_game_pattern_probability.mojo`, `nim/p/penney_game_pattern_probability.nim`, `odin/p/penney_game_pattern_probability.odin`, `rust/p/penney_game_pattern_probability.rs`, `v/p/penney_game_pattern_probability.v`, and `zig/p/penney_game_pattern_probability.zig`.
