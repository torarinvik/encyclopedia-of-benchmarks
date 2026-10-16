# Ascon Digest

This benchmark ports the pinned C# `AsconDigest` class from TheAlgorithms/C-Sharp. The input selects one of its two exposed variants: `0` for Ascon-Hash (12-round absorption/squeeze permutation) or `1` for Ascon-HashA (8-round absorption/squeeze permutation). Both variants return 32 digest bytes.

## Contract

- Input is `[variant, byte_length, byte_0, ..., byte_(byte_length-1)]`, with variant 0 or 1 and message length from 0 through 4,096. Each byte is a signed-i64 array element in `[0, 255]`.
- The output is the 32 raw digest bytes in the same big-endian order written by the source class. The C# source applies its fixed 12-round finalization permutation for both variants; the ports preserve this behavior exactly.
- Invalid input returns `-1`; insufficient output capacity returns `-2` without writing; success returns 32.
- The implementations use portable scalar 64-bit bitwise operations and rotations, with no CPU-specific instructions.

The workload includes every published source test vector for both variants, empty input, rate-boundary lengths, all byte values, and longer messages. The verifier also checks randomized messages, invalid input, and output capacity.

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm ascon_digest --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/ascon_digest/rust/build.json
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/a/ascon_digest.c`](../../../c/a/ascon_digest.c) |
| C3 | [`c3/a/ascon_digest.c3`](../../../c3/a/ascon_digest.c3) |
| C++ | [`cpp/a/ascon_digest.cpp`](../../../cpp/a/ascon_digest.cpp) |
| Elisa | [`elisa/a/ascon_digest.elisa`](../../../elisa/a/ascon_digest.elisa) |
| Nim | [`nim/a/ascon_digest.nim`](../../../nim/a/ascon_digest.nim) |
| Odin | [`odin/a/ascon_digest.odin`](../../../odin/a/ascon_digest.odin) |
| Rust | [`rust/a/ascon_digest.rs`](../../../rust/a/ascon_digest.rs) |
| V | [`v/a/ascon_digest.v`](../../../v/a/ascon_digest.v) |
| Zig | [`zig/a/ascon_digest.zig`](../../../zig/a/ascon_digest.zig) |

## Pinned source

- TheAlgorithms/C-Sharp [`AsconDigest.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Crypto/Digests/AsconDigest.cs)
- TheAlgorithms/C-Sharp [`AsconDigestTests.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms.Tests/Crypto/Digests/AsconDigestTests.cs)
