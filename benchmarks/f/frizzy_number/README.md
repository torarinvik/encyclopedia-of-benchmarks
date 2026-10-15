# Frizzy number

## Contract

The pinned Java and Rust implementations take `(base, n)` and sum `base^i`
for each set bit `i` in the binary representation of `n`. For example, with
base 3 and `n = 4` (`100₂`), the result is `3² = 9`. The binary set-bit
positions become exponents in the chosen base.

The benchmark uses the two-input `binary_scalar` ABI. Inputs are ordered
`[base, n]`, with `2 <= base <= 10` and `0 <= n <= 1023`. The result is an
exact signed integer. These bounds preserve the source's signed 32-bit input
domain and keep the largest output, `1,111,111,111`, within signed 32-bit
range. Invalid inputs return `-1`. Both pinned sources return zero when
`n == 0`.

## Workload and build

[`workload.json`](workload.json) covers the source examples, several bases,
zero, and the maximum bounded index.

Build and record with the binary scalar ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm frizzy_number --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/f/frizzy_number/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/f/frizzy_number.c`](../../../c/f/frizzy_number.c) |
| C3 | [`c3/f/frizzy_number.c3`](../../../c3/f/frizzy_number.c3) |
| C++ | [`cpp/f/frizzy_number.cpp`](../../../cpp/f/frizzy_number.cpp) |
| Elisa | [`elisa/f/frizzy_number.elisa`](../../../elisa/f/frizzy_number.elisa) |
| Nim | [`nim/f/frizzy_number.nim`](../../../nim/f/frizzy_number.nim) |
| Odin | [`odin/f/frizzy_number.odin`](../../../odin/f/frizzy_number.odin) |
| Rust | [`rust/f/frizzy_number.rs`](../../../rust/f/frizzy_number.rs) |
| V | [`v/f/frizzy_number.v`](../../../v/f/frizzy_number.v) |
| Zig | [`zig/f/frizzy_number.zig`](../../../zig/f/frizzy_number.zig) |

## Pinned sources

- [Java `FrizzyNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FrizzyNumber.java)
- [Rust `frizzy_number.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/frizzy_number.rs)
