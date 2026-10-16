# Primitive root search

Find the first integer whose first `modulus - 1` powers produce distinct residues modulo the requested modulus. This follows the search performed by Python's `find_primitive` routine.

## Contract

- Input is a one-element signed 64-bit array `[modulus]`, with `2 <= modulus <= 127`.
- Return the first candidate in ascending order whose powers for exponents `0..modulus-2` are all distinct modulo `modulus`.
- Return `0` when no candidate satisfies that test. Return `-1` for a malformed array or an out-of-range modulus.
- The bounded exhaustive search runs in `O(modulus^2)` time and uses a fixed 127-entry residue table.

The upstream docstring says “if one exists,” but its implementation tests exactly `modulus - 1` distinct residues. As a result, this search finds primitive roots for prime moduli and returns no candidate for composite moduli such as 4, even though 4 has a primitive root under the conventional totient-based definition. The benchmark preserves the implemented search behavior.

## Source and verification

The benchmark is based on Python's [`find_primitive`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/diffie.py). Its function computes modular powers, rejects a candidate at the first repeated residue, and returns the first candidate that completes the `modulus - 1` checks.

[`workload.json`](workload.json) covers small primes, the upper bound, composite moduli, and invalid arrays. The independent oracle is [`primitive_root_oracle.py`](../../primitive_root_oracle.py).

Run the nine-language verifier with:

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms primitive_root
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/primitive_root.c`](../../../c/p/primitive_root.c) |
| C3 | [`c3/p/primitive_root.c3`](../../../c3/p/primitive_root.c3) |
| C++ | [`cpp/p/primitive_root.cpp`](../../../cpp/p/primitive_root.cpp) |
| Elisa | [`elisa/p/primitive_root.elisa`](../../../elisa/p/primitive_root.elisa) |
| Nim | [`nim/p/primitive_root.nim`](../../../nim/p/primitive_root.nim) |
| Odin | [`odin/p/primitive_root.odin`](../../../odin/p/primitive_root.odin) |
| Rust | [`rust/p/primitive_root.rs`](../../../rust/p/primitive_root.rs) |
| V | [`v/p/primitive_root.v`](../../../v/p/primitive_root.v) |
| Zig | [`zig/p/primitive_root.zig`](../../../zig/p/primitive_root.zig) |
