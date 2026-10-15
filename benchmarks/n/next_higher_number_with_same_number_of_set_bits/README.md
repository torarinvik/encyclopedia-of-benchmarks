# Next higher number with the same number of set bits

This benchmark returns the smallest integer greater than the input that has the same number of one-bits.

## Contract

- The signed 64-bit ABI accepts inputs from `1` through `1,073,741,823` (`2^30 - 1`).
- A valid input returns the next higher positive integer with equal population count. This bound keeps the result within positive signed 32-bit range, matching the common C++/Java behavior.
- Inputs at or below zero and inputs above the bound return `-1`. The pinned C++ function returns zero for input zero via its `if (x)` guard; the pinned Java function divides by zero there. The benchmark normalizes both source edge behaviors to the same invalid sentinel.
- The implementation follows the bit trick: isolate the rightmost set bit `c = x & -x`, form `r = x + c`, then combine `r` with `((x ^ r) / c) >> 2`.

The C++ source uses an unsigned 64-bit input and the Java source uses signed 32-bit `int`. They implement the same operation on this shared bounded domain. Java's `NextHigherSameBitCount` is mapped to this benchmark as the same algorithm. This is distinct from [`next_power_of_two`](../next_power_of_two/README.md), which rounds upward to a power of two regardless of the input's set-bit count.

## Workload and build

[`workload.json`](workload.json) covers small values, multi-bit examples, a single-bit input, the upper boundary, and invalid inputs including zero, negative values, and the first value above the bound. Build and record with the `scalar` ABI:

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
| Nim | [`nim/n/next_higher_number_with_same_number_of_set_bits.nim`](../../../nim/n/next_higher_number_with_same_number_of_set_bits.nim) |
| Odin | [`odin/n/next_higher_number_with_same_number_of_set_bits.odin`](../../../odin/n/next_higher_number_with_same_number_of_set_bits.odin) |
| Rust | [`rust/n/next_higher_number_with_same_number_of_set_bits.rs`](../../../rust/n/next_higher_number_with_same_number_of_set_bits.rs) |
| V | [`v/n/next_higher_number_with_same_number_of_set_bits.v`](../../../v/n/next_higher_number_with_same_number_of_set_bits.v) |
| Zig | [`zig/n/next_higher_number_with_same_number_of_set_bits.zig`](../../../zig/n/next_higher_number_with_same_number_of_set_bits.zig) |

## Pinned sources

- [C++ `next_higher_number_with_same_number_of_set_bits.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/bit_manipulation/next_higher_number_with_same_number_of_set_bits.cpp)
- [Java `NextHigherSameBitCount.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/NextHigherSameBitCount.java)
