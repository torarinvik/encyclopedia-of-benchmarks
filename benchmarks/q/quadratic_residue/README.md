# Quadratic residue: Legendre symbol

This benchmark isolates `legendre_symbol` from the pinned Rust `quadratic_residue.rs` module. The source file also contains Cipolla and Tonelli–Shanks root-finding routines; those are not included in this workload.

## Contract

- Input is `[a, p]`, where `a` is a canonical residue in `[0,p)` and `p` is one of the odd primes `{3,5,7,11,13,17,19,23,29,31,37,41,43,47,53}`.
- Return 0 when `a=0`; otherwise return 1 when `a` is a square modulo `p`, and -1 when it is a non-residue. The implementation uses Euler's criterion and repeated squaring.
- Incorrect length, unsupported modulus, or noncanonical `a` returns -1. The bounded modulus keeps all intermediate products safe in signed 64-bit arithmetic.
- Time is O(log p), with O(1) auxiliary space.

## Workload

[`workload.json`](workload.json) covers zero, residues, non-residues, the largest prime and invalid inputs. The oracle is [`benchmarks/quadratic_residue_oracle.py`](../../quadratic_residue_oracle.py). The comparison model is `i64_array_scalar_call`.

## Pinned source

[TheAlgorithms/Rust `quadratic_residue.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/quadratic_residue.rs) documents the Legendre-symbol operation. Its implementation's explicit `a == 0` branch is retained.

## Implementations

| Language | Source |
|---|---|
| C | [`c/q/quadratic_residue.c`](../../../c/q/quadratic_residue.c) |
| C3 | [`c3/q/quadratic_residue.c3`](../../../c3/q/quadratic_residue.c3) |
| C++ | [`cpp/q/quadratic_residue.cpp`](../../../cpp/q/quadratic_residue.cpp) |
| Elisa | [`elisa/q/quadratic_residue.elisa`](../../../elisa/q/quadratic_residue.elisa) |
| Nim | [`nim/q/quadratic_residue.nim`](../../../nim/q/quadratic_residue.nim) |
| Odin | [`odin/q/quadratic_residue.odin`](../../../odin/q/quadratic_residue.odin) |
| Rust | [`rust/q/quadratic_residue.rs`](../../../rust/q/quadratic_residue.rs) |
| V | [`v/q/quadratic_residue.v`](../../../v/q/quadratic_residue.v) |
| Zig | [`zig/q/quadratic_residue.zig`](../../../zig/q/quadratic_residue.zig) |
