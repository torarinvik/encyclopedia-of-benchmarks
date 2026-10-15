# Majority Elements at Half Threshold

This benchmark ports the Java `MajorityElement.majority` method, which returns every distinct value whose frequency is at least `floor(n / 2)`. Unlike a strict-majority vote, it can return multiple values; for example, two different values in a two-element array both qualify. Empty input returns an empty result.

Java returns results by iterating a `HashMap`, whose iteration order is unspecified. This contract sorts qualifying values in ascending order so the output is stable across the nine ports.

## Contract

- Input is an array of 0 through 256 signed 32-bit integers packed as i64 values.
- The threshold is `floor(input_length / 2)`. Each distinct value whose count is at least that threshold is returned once.
- Output is the qualifying values in ascending order, encoded as little-endian signed 32-bit integers. The return value is the number of values.
- Invalid length or out-of-range values return `-1`; insufficient output capacity returns `-2`.

The C ABI entry point is:

```c
int64_t majority_elements_floor_half(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity);
```

| Language | Source |
|---|---|
| C | [`c/m/majority_elements_floor_half.c`](../../../c/m/majority_elements_floor_half.c) |
| C3 | [`c3/m/majority_elements_floor_half.c3`](../../../c3/m/majority_elements_floor_half.c3) |
| C++ | [`cpp/m/majority_elements_floor_half.cpp`](../../../cpp/m/majority_elements_floor_half.cpp) |
| Elisa | [`elisa/m/majority_elements_floor_half.elisa`](../../../elisa/m/majority_elements_floor_half.elisa) |
| Nim | [`nim/m/majority_elements_floor_half.nim`](../../../nim/m/majority_elements_floor_half.nim) |
| Odin | [`odin/m/majority_elements_floor_half.odin`](../../../odin/m/majority_elements_floor_half.odin) |
| Rust | [`rust/m/majority_elements_floor_half.rs`](../../../rust/m/majority_elements_floor_half.rs) |
| V | [`v/m/majority_elements_floor_half.v`](../../../v/m/majority_elements_floor_half.v) |
| Zig | [`zig/m/majority_elements_floor_half.zig`](../../../zig/m/majority_elements_floor_half.zig) |

## Source

- [Java `MajorityElement.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/hashmap/hashing/MajorityElement.java)
- [Boyer–Moore strict-majority benchmark](../../b/boyer_moore_majority_vote/README.md)
