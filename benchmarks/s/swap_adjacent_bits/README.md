# Swap adjacent bits

Exchange every neighboring pair of bits in the input's low 32-bit word, following the pinned mask-and-shift algorithms.

## Contract

- The signed scalar ABI accepts integers from 0 through `0x3fffffff` (1,073,741,823). Inputs outside this range return `-1`.
- The output is `((n & 0xAAAAAAAA) >> 1) | ((n & 0x55555555) << 1)`. Results are nonnegative and fit in signed 32-bit range.
- This bounded domain keeps the Java `int`, Rust `u32`, and Python/Dart integer variants equivalent while retaining the same adjacent-bit transformation.

## Source semantics

The canonical source is the pinned [Java `SwapAdjacentBits.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/SwapAdjacentBits.java). The Python [`swap_all_odd_and_even_bits.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/swap_all_odd_and_even_bits.py), Dart [`swap_all_odd_and_even_bits.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/swap_all_odd_and_even_bits.dart), and Rust [`swap_odd_even_bits.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/swap_odd_even_bits.rs) use the same masks and shifts on their corresponding 32-bit word. Their source names describe the same operation. This differs from [`bit_swap`](../../b/bit_swap/README.md), which exchanges two selected bit positions.

## Workload

[`workload.json`](workload.json) covers single-bit moves in both directions, unchanged and alternating patterns, the upper input bound, and invalid boundaries.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/swap_adjacent_bits.c`](../../../c/s/swap_adjacent_bits.c) |
| C3 | [`c3/s/swap_adjacent_bits.c3`](../../../c3/s/swap_adjacent_bits.c3) |
| C++ | [`cpp/s/swap_adjacent_bits.cpp`](../../../cpp/s/swap_adjacent_bits.cpp) |
| Elisa | [`elisa/s/swap_adjacent_bits.elisa`](../../../elisa/s/swap_adjacent_bits.elisa) |
| Nim | [`nim/s/swap_adjacent_bits.nim`](../../../nim/s/swap_adjacent_bits.nim) |
| Odin | [`odin/s/swap_adjacent_bits.odin`](../../../odin/s/swap_adjacent_bits.odin) |
| Rust | [`rust/s/swap_adjacent_bits.rs`](../../../rust/s/swap_adjacent_bits.rs) |
| V | [`v/s/swap_adjacent_bits.v`](../../../v/s/swap_adjacent_bits.v) |
| Zig | [`zig/s/swap_adjacent_bits.zig`](../../../zig/s/swap_adjacent_bits.zig) |

Build with `python3 benchmarks/build_scalar.py --algorithm swap_adjacent_bits --language LANGUAGE` and record with `benchmarks/run_scalar.py`.
