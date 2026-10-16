# Prime factorial

The pinned MATLAB-Octave file is an interactive script, despite the name `prime_factorial`. It asks for an integer and prints the input's **distinct prime divisors** in ascending order. It does not compute a factorial, preserve prime multiplicities, or emit prime/exponent pairs. This benchmark normalizes that script to a callable function with a bounded integer input.

## Contract

- Input is one signed 64-bit integer `n` in `[2, 4096]`.
- Return each distinct prime divisor of `n` in ascending order, encoded as a sequence of little-endian `u32` values. The return value is the number of bytes written.
- Return `-1` for inputs outside the supported range.
- Return `-2` when the output buffer is too small, without writing bytes. The largest output is 20 bytes: the product of the five distinct primes `2, 3, 5, 7, 11` is within the bound, while multiplying by 13 exceeds it.
- The port preserves the source's search strategy: scan candidates from `2` through `n`, test each candidate by trying divisors from `2` through `floor(candidate / 2) + 1`, and include it once if it is prime and divides `n`.

This differs from [`prime_factors`](../prime_factors/README.md), which retains multiplicity, and [`prime_factorization`](../prime_factorization/README.md), which returns prime/exponent pairs.

## Source and workload

The implementation follows the pinned [TheAlgorithms/MATLAB-Octave `prime_factorial.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/maths/prime_factorial.m). [`workload.json`](workload.json) covers small primes, repeated powers, composites with multiple distinct factors, the five-factor maximum, the upper bound, invalid integers, and insufficient capacity.

Build with the scalar-to-bytes ABI:

```sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm prime_factorial --language rust
python3 benchmarks/run_i64_scalar_bytes_output.py --build-manifest build/i64_scalar_bytes_output/p/prime_factorial/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/p/prime_factorial.c`](../../../c/p/prime_factorial.c) |
| C3 | [`c3/p/prime_factorial.c3`](../../../c3/p/prime_factorial.c3) |
| C++ | [`cpp/p/prime_factorial.cpp`](../../../cpp/p/prime_factorial.cpp) |
| Elisa | [`elisa/p/prime_factorial.elisa`](../../../elisa/p/prime_factorial.elisa) |
| Nim | [`nim/p/prime_factorial.nim`](../../../nim/p/prime_factorial.nim) |
| Odin | [`odin/p/prime_factorial.odin`](../../../odin/p/prime_factorial.odin) |
| Rust | [`rust/p/prime_factorial.rs`](../../../rust/p/prime_factorial.rs) |
| V | [`v/p/prime_factorial.v`](../../../v/p/prime_factorial.v) |
| Zig | [`zig/p/prime_factorial.zig`](../../../zig/p/prime_factorial.zig) |
