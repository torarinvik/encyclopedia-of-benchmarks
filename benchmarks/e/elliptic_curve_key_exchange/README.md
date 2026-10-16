# Bounded elliptic-curve Diffie–Hellman

This contract standardizes elliptic-curve Diffie–Hellman over affine point addition and binary double-and-add. It combines the separate Rust `elliptic_curve` point-group source with the C++ key-exchange demo, computing each party's public point and the common shared point on a small prime field.

## Contract

Input is `[p, a, b, gx, gy, alice_scalar, bob_scalar]` for the short Weierstrass curve `y² = x³ + ax + b (mod p)`. The prime `p` is 5 through 251, `a`, `b`, `gx`, and `gy` are normalized residues, the curve discriminant is nonzero, and `(gx, gy)` lies on the curve. Scalars are in 1 through 1,024. Invalid inputs return `-1`.

Affine addition uses modular inverses in `F_p`; scalar multiplication uses left-to-right-independent binary double-and-add. Output is three point pairs (Alice public, Bob public, shared), each encoded as two little-endian signed 64-bit values. The point at infinity is `(-1, -1)`. The shared point is computed both ways and must agree. Output capacity must be at least 48 bytes; otherwise the call returns `-2` without writing. This bounded contract is for deterministic algorithm comparison and makes no cryptographic security claim.

The Rust source exposes validated affine points, the identity, and the group addition/negation/subtraction laws; scalar multiplication here composes its point addition law. The C++ source implements modular point addition and double-and-add multiplication, then demonstrates ECDH with fixed large values. Its custom 128/256-bit arithmetic tests and console output are excluded.

[`workload.json`](workload.json) includes small prime curves, infinity results, doubling, nontrivial scalars, malformed/singular inputs, and output-capacity edges. The verifier adds deterministic valid-curve points and scalar pairs.

## Pinned sources

- [Rust `elliptic_curve.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/math/elliptic_curve.rs)
- [C++ `elliptic_curve_key_exchange.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/elliptic_curve_key_exchange.cpp)
- [Additional C++ repository copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/ciphers/elliptic_curve_key_exchange.cpp)

## Implementations

| Language | Port |
| --- | --- |
| C | `c/e/elliptic_curve_key_exchange.c` |
| C3 | `c3/e/elliptic_curve_key_exchange.c3` |
| C++ | `cpp/e/elliptic_curve_key_exchange.cpp` |
| Elisa | `elisa/e/elliptic_curve_key_exchange.elisa` |
| Nim | `nim/e/elliptic_curve_key_exchange.nim` |
| Odin | `odin/e/elliptic_curve_key_exchange.odin` |
| Rust | `rust/e/elliptic_curve_key_exchange.rs` |
| V | `v/e/elliptic_curve_key_exchange.v` |
| Zig | `zig/e/elliptic_curve_key_exchange.zig` |

Run the focused verifier with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm elliptic_curve_key_exchange`.

## Port validation status

The focused verifier passes for C, C++, Rust, Zig, C3, Nim, Odin, and V (211 oracle inputs and 8 workload records per port). Elisa remains unverified: the configured `elisac-stage1` compiler accepts the source but omits the implementation symbol required by its exported ABI wrapper (`_ec_run_impl`), so the runner fails at link time with an undefined symbol. It is retained as the closest native translation and is not counted as passing.
