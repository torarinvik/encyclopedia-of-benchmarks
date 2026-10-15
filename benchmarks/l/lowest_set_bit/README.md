# Lowest set bit

## Contract

The pinned Java `LowestSetBit.isolateLowestSetBit(int)` returns the isolated
lowest one bit as a mask: `n & -n`. For example, `18` (`10010₂`) returns `2`
(`00010₂`). Zero returns zero.

This benchmark uses the signed 64-bit scalar ABI while preserving the Java
function's nonnegative `int32` domain, `0..=2,147,483,647`. Inputs outside
that range return `-1` as the benchmark's invalid-input sentinel. The source
also accepts negative Java `int` values, but they are outside this shared
contract. Within the contract, the result is zero or a power-of-two mask no
greater than `1,073,741,824`.

The source file also provides `clearLowestSetBit`, which returns
`n & (n - 1)`; that separate operation is not measured here. This benchmark
returns the isolated mask value, unlike `rightmost_set_bit`, which returns
the one-based position of that bit.

## Workload and build

[`workload.json`](workload.json) covers zero, single-bit and multi-bit
values, the largest supported input, and inputs outside the contract. It
uses the unary `scalar` ABI.

Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm lowest_set_bit --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/l/lowest_set_bit/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/l/lowest_set_bit.c`](../../../c/l/lowest_set_bit.c) |
| C3 | [`c3/l/lowest_set_bit.c3`](../../../c3/l/lowest_set_bit.c3) |
| C++ | [`cpp/l/lowest_set_bit.cpp`](../../../cpp/l/lowest_set_bit.cpp) |
| Elisa | [`elisa/l/lowest_set_bit.elisa`](../../../elisa/l/lowest_set_bit.elisa) |
| Nim | [`nim/l/lowest_set_bit.nim`](../../../nim/l/lowest_set_bit.nim) |
| Odin | [`odin/l/lowest_set_bit.odin`](../../../odin/l/lowest_set_bit.odin) |
| Rust | [`rust/l/lowest_set_bit.rs`](../../../rust/l/lowest_set_bit.rs) |
| V | [`v/l/lowest_set_bit.v`](../../../v/l/lowest_set_bit.v) |
| Zig | [`zig/l/lowest_set_bit.zig`](../../../zig/l/lowest_set_bit.zig) |

## Pinned source

- [Java `LowestSetBit.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/LowestSetBit.java)
