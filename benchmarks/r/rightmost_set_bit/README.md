# Rightmost set bit

## Contract

The pinned Rust function `index_of_rightmost_set_bit` accepts an `i32` and
returns a `Result<u32, String>`. For a positive input it isolates the lowest
set bit with `isolate_lowest_one()`, then returns that bit's trailing-zero
count plus one. The result is therefore the **one-based** position counted
from the least significant bit: `18` (`10010₂`) returns `2`, and `12`
(`1100₂`) returns `3`.

This benchmark uses the signed 64-bit scalar ABI but keeps the source's
positive `i32` input domain, `1..=2,147,483,647`. Zero and negative inputs
produce the source error and map to `-1`; values above `i32::MAX` are outside
the pinned function's type and also map to `-1` in the benchmark contract.
Results are between 1 and 31.

This operation differs from `highest_set_bit`, which returns the zero-based
position of the most significant bit; from `count_leading_zeros`, which
counts leading zeros in a fixed 32-bit word; and from
`clear_leftmost_set_bit`, which returns the input with its most significant
set bit cleared.

## Workload and build

[`workload.json`](workload.json) covers invalid inputs, the first bit, odd
inputs, powers of two, and mixed bit patterns. It uses the unary `scalar`
ABI.

Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm rightmost_set_bit --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/r/rightmost_set_bit/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/r/rightmost_set_bit.c`](../../../c/r/rightmost_set_bit.c) |
| C3 | [`c3/r/rightmost_set_bit.c3`](../../../c3/r/rightmost_set_bit.c3) |
| C++ | [`cpp/r/rightmost_set_bit.cpp`](../../../cpp/r/rightmost_set_bit.cpp) |
| Elisa | [`elisa/r/rightmost_set_bit.elisa`](../../../elisa/r/rightmost_set_bit.elisa) |
| Nim | [`nim/r/rightmost_set_bit.nim`](../../../nim/r/rightmost_set_bit.nim) |
| Odin | [`odin/r/rightmost_set_bit.odin`](../../../odin/r/rightmost_set_bit.odin) |
| Rust | [`rust/r/rightmost_set_bit.rs`](../../../rust/r/rightmost_set_bit.rs) |
| V | [`v/r/rightmost_set_bit.v`](../../../v/r/rightmost_set_bit.v) |
| Zig | [`zig/r/rightmost_set_bit.zig`](../../../zig/r/rightmost_set_bit.zig) |

## Pinned source

- [Rust `rightmost_set_bit.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/rightmost_set_bit.rs)
