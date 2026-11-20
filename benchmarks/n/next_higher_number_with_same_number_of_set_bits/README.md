# Next higher number with the same number of set bits

This benchmark returns the smallest integer greater than the input that has the same number of one-bits. The RosettaCodeData title “Gospers-hack” maps to this existing canonical package; it does not justify a second copy of the same fixed-popcount successor.

## Contract

- ABI is `scalar_call`, with one signed 64-bit input.
- Valid inputs are `1..1,073,741,823` (`2^30 - 1`). The result is the least larger positive integer with the same population count and is at most `1,610,612,735`.
- Inputs outside the valid domain return `-1`. The benchmark normalizes the pinned C++ zero-input return and the pinned Java zero-input division behavior to this sentinel.
- The primary reference isolates the lowest set bit `c = x & -x`, forms `r = x + c`, and combines `r` with `((x ^ r) / c) >> 2`.
- The independent reference works on the binary string: it moves the rightmost movable `1` one position left, then packs the remaining ones at the low end. It does not use the primary arithmetic formula.

The C++ source uses an unsigned 64-bit input and the Java source uses signed 32-bit `int`. They implement the same operation on this shared bounded domain. Java's `NextHigherSameBitCount` is mapped to this benchmark as the same algorithm. This is distinct from [`next_power_of_two`](../next_power_of_two/README.md), which rounds upward to a power of two regardless of the input's set-bit count.

The clean-room ports cover all ten supported benchmark languages, including
Mojo, with the same `1..=1,073,741,823` input bound and sentinel behavior.

## Workload and build

[`workload.json`](workload.json) uses the standard `scalar_call` schema and covers small values, multiple carry patterns, a single-bit input, the upper boundary, and invalid signed values. `verify_workload.py` compares every pinned fixture against both references; `check_inventory.py` checks the ten source paths and package provenance without executing a port. Build and record with the `scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm next_higher_number_with_same_number_of_set_bits --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/n/next_higher_number_with_same_number_of_set_bits/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/n/next_higher_number_with_same_number_of_set_bits.c`](../../../c/n/next_higher_number_with_same_number_of_set_bits.c) |
| C3 | [`c3/n/next_higher_number_with_same_number_of_set_bits.c3`](../../../c3/n/next_higher_number_with_same_number_of_set_bits.c3) |
| C++ | [`cpp/n/next_higher_number_with_same_number_of_set_bits.cpp`](../../../cpp/n/next_higher_number_with_same_number_of_set_bits.cpp) |
| Elisa | [`elisa/n/next_higher_number_with_same_number_of_set_bits.elisa`](../../../elisa/n/next_higher_number_with_same_number_of_set_bits.elisa) |
| Mojo | [`mojo/n/next_higher_number_with_same_number_of_set_bits.mojo`](../../../mojo/n/next_higher_number_with_same_number_of_set_bits.mojo) |
| Nim | [`nim/n/next_higher_number_with_same_number_of_set_bits.nim`](../../../nim/n/next_higher_number_with_same_number_of_set_bits.nim) |
| Odin | [`odin/n/next_higher_number_with_same_number_of_set_bits.odin`](../../../odin/n/next_higher_number_with_same_number_of_set_bits.odin) |
| Rust | [`rust/n/next_higher_number_with_same_number_of_set_bits.rs`](../../../rust/n/next_higher_number_with_same_number_of_set_bits.rs) |
| V | [`v/n/next_higher_number_with_same_number_of_set_bits.v`](../../../v/n/next_higher_number_with_same_number_of_set_bits.v) |
| Zig | [`zig/n/next_higher_number_with_same_number_of_set_bits.zig`](../../../zig/n/next_higher_number_with_same_number_of_set_bits.zig) |

## Pinned sources

- HAKMEM, [Item 175](https://dspace.mit.edu/bitstream/handle/1721.1/6086/AIM-239.pdf), is the primary algorithm reference for the fixed-popcount successor.
- [C++ `next_higher_number_with_same_number_of_set_bits.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/bit_manipulation/next_higher_number_with_same_number_of_set_bits.cpp)
- [Java `NextHigherSameBitCount.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/NextHigherSameBitCount.java)
- RosettaCodeData's pinned [popular task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) is cited only for discovering and mapping “Gospers-hack” to this canonical operation.
