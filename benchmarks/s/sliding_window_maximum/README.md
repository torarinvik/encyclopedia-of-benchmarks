# Sliding window maximum

## Contract

Return the maximum value in every contiguous window of width `k`, in left-to-right order. Input is `[n, k, values...]`, where `n` is 0 through 1,024, `k` is 1 through 1,024, and exactly `n` signed 32-bit values follow. If `n < k`, return an empty result. Invalid shape, bounds, or values return `-1`; insufficient output capacity returns `-2`. Each maximum is emitted as a little-endian signed 64-bit word, and success returns the number of windows.

The pinned Java and Python implementations both maintain a deque of candidate indices in decreasing value order, giving `O(n)` time. The existing `max_sum_sliding_window` benchmark returns the largest window sum; this benchmark returns each window's maximum.

The shared ABI is:

```c
int64_t sliding_window_maximum(const int64_t *input, size_t length,
                               uint8_t *output, size_t output_capacity);
```

## Workload

[`workload.json`](workload.json) covers the source example, width one and full-array windows, duplicates, increasing and decreasing sequences, empty and undersized inputs, invalid widths, and the maximum array length.

The shared byte-output runner validates the packed input, reproduces the monotone-deque window maxima, and packs each result as a little-endian signed 64-bit word.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm sliding_window_maximum --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm sliding_window_maximum
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sliding_window_maximum.c`](../../../c/s/sliding_window_maximum.c) |
| C3 | [`c3/s/sliding_window_maximum.c3`](../../../c3/s/sliding_window_maximum.c3) |
| C++ | [`cpp/s/sliding_window_maximum.cpp`](../../../cpp/s/sliding_window_maximum.cpp) |
| Elisa | [`elisa/s/sliding_window_maximum.elisa`](../../../elisa/s/sliding_window_maximum.elisa) |
| Nim | [`nim/s/sliding_window_maximum.nim`](../../../nim/s/sliding_window_maximum.nim) |
| Odin | [`odin/s/sliding_window_maximum.odin`](../../../odin/s/sliding_window_maximum.odin) |
| Rust | [`rust/s/sliding_window_maximum.rs`](../../../rust/s/sliding_window_maximum.rs) |
| V | [`v/s/sliding_window_maximum.v`](../../../v/s/sliding_window_maximum.v) |
| Zig | [`zig/s/sliding_window_maximum.zig`](../../../zig/s/sliding_window_maximum.zig) |

## Upstream references

- [Java `SlidingWindowMaximum.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/queues/SlidingWindowMaximum.java)
- [Python `sliding_window_maximum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/sliding_window_maximum.py)
