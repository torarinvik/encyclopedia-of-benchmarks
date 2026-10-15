# Binary prime constant sequence

Return the first `n` terms of the prime characteristic sequence. At one-based
index `i`, the term is `1` when `i` is prime and `0` otherwise. The sequence
begins `0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, ...`.

## Contract

- Input is a one-element signed 64-bit array `[n]`, with `0 <= n <= 4096`.
- Output is the first `n` terms, one byte per term (`0x00` or `0x01`). The
  function returns the term count, so an empty prefix returns zero.
- Malformed input or a count outside the bound returns `-1`. Insufficient
  output capacity returns `-2`.
- The pinned C# source exposes an infinite `IEnumerable<BigInteger>` and takes
  no count. The benchmark consumes a bounded prefix of that sequence. The
  source emits zeros in the gaps between prime values and one for each prime.

## Related benchmarks

This output is distinct from `prime_numbers`, which returns prime values up to
an inclusive limit, and `first_n_primes`, which returns the first `n` prime
values. This benchmark keeps every index and encodes primality as a zero or
one term.

The source is [TheAlgorithms C# `BinaryPrimeConstantSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/BinaryPrimeConstantSequence.cs).
The nine ports emit the same prefix using an increasing prime scan.

## Workload and build

[`workload.json`](workload.json) covers the empty prefix, initial terms,
larger prefixes, and malformed or out-of-range inputs. The byte-output runner
uses an independent primality oracle for the expected bytes.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm binary_prime_constant_sequence --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/binary_prime_constant_sequence/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/b/binary_prime_constant_sequence.c`](../../../c/b/binary_prime_constant_sequence.c) |
| C3 | [`c3/b/binary_prime_constant_sequence.c3`](../../../c3/b/binary_prime_constant_sequence.c3) |
| C++ | [`cpp/b/binary_prime_constant_sequence.cpp`](../../../cpp/b/binary_prime_constant_sequence.cpp) |
| Elisa | [`elisa/b/binary_prime_constant_sequence.elisa`](../../../elisa/b/binary_prime_constant_sequence.elisa) |
| Nim | [`nim/b/binary_prime_constant_sequence.nim`](../../../nim/b/binary_prime_constant_sequence.nim) |
| Odin | [`odin/b/binary_prime_constant_sequence.odin`](../../../odin/b/binary_prime_constant_sequence.odin) |
| Rust | [`rust/b/binary_prime_constant_sequence.rs`](../../../rust/b/binary_prime_constant_sequence.rs) |
| V | [`v/b/binary_prime_constant_sequence.v`](../../../v/b/binary_prime_constant_sequence.v) |
| Zig | [`zig/b/binary_prime_constant_sequence.zig`](../../../zig/b/binary_prime_constant_sequence.zig) |
