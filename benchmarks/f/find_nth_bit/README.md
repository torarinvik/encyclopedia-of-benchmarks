# Find the nth bit

Return the bit at a requested 1-based position in a nonnegative 32-bit integer. The contract follows the pinned Java `FindNthBit.findNthBit` expression over its nonnegative input subset.

## Contract

- Inputs are two unsigned 64-bit ABI values `[num, n]`.
- Valid values are `num` in `[0, 2^31 - 1]` and `n` in `[1, 31]`.
- Return `(num & (1 << (n - 1))) >> (n - 1)`, which is 0 or 1 on this domain. Position 1 is the least significant bit.
- Invalid ABI inputs return `-1`. The pinned Java source throws `IllegalArgumentException` for `n < 1`; this benchmark maps invalid pairs to the shared sentinel and bounds positions at 31 so the Java signed-int expression stays in its positive range. Negative `num` values are outside the benchmark domain.
- The operation takes `O(1)` time and `O(1)` space.

## Source and related algorithms

The pinned [Java `FindNthBit.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/FindNthBit.java) validates that the 1-based position is at least 1 and extracts the selected bit with a shift and mask. Existing `highest_set_bit`, `rightmost_set_bit`, and `lowest_set_bit` benchmarks find positions from the number itself; this benchmark reads one requested position and returns that bit's value.

## Workload and build

[`workload.json`](workload.json) covers set and clear positions, the largest supported position and number, plus invalid positions and values. All nine ports use the shared `binary_scalar` ABI.

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm find_nth_bit --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/f/find_nth_bit/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/f/find_nth_bit.c`](../../../c/f/find_nth_bit.c) |
| C3 | [`c3/f/find_nth_bit.c3`](../../../c3/f/find_nth_bit.c3) |
| C++ | [`cpp/f/find_nth_bit.cpp`](../../../cpp/f/find_nth_bit.cpp) |
| Elisa | [`elisa/f/find_nth_bit.elisa`](../../../elisa/f/find_nth_bit.elisa) |
| Nim | [`nim/f/find_nth_bit.nim`](../../../nim/f/find_nth_bit.nim) |
| Odin | [`odin/f/find_nth_bit.odin`](../../../odin/f/find_nth_bit.odin) |
| Rust | [`rust/f/find_nth_bit.rs`](../../../rust/f/find_nth_bit.rs) |
| V | [`v/f/find_nth_bit.v`](../../../v/f/find_nth_bit.v) |
| Zig | [`zig/f/find_nth_bit.zig`](../../../zig/f/find_nth_bit.zig) |
