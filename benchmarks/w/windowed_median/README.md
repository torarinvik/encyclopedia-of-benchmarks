# Windowed median over a stream

Insert each input value into a fixed-width trailing window and emit the median after every insertion. Prefixes shorter than the configured window produce medians over the values received so far.

## Contract

- Input is packed as `[window_size, stream_length, values...]` in signed 64-bit integers, with exact packing and no trailing fields.
- `window_size` is 1 through 64, `stream_length` is 1 through 128, and values are in `[-1,000,000, 1,000,000]`.
- For every prefix, use its last `min(window_size, prefix_length)` values. An odd-sized window returns its middle value; an even-sized window returns the arithmetic mean of its two middle values.
- Emit one result per inserted value as an 8-byte little-endian binary64 value. The function returns `8 * stream_length` bytes.
- Malformed packing or out-of-domain fields return `-1`; insufficient output capacity returns `-2`.

The pinned C++ source computes medians as `float` (binary32). The bounded integer inputs make all selected values and half-integer averages exactly representable in binary32, so widening those results to binary64 preserves them exactly. The source's `getMedian` assumes a nonempty window; zero window size and empty streams are excluded.

## Sources and distinction

This is a fixed-window streaming median backed by a queue and ordered multiset in the source. It differs from the one-shot [`median`](../../m/median/README.md) benchmark and from running medians whose retained stream grows without a fixed window.

- [TheAlgorithms/C-Plus-Plus pinned `windowed_median.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/probability/windowed_median.cpp)
- [TheAlgorithms/C-Plus-Plus-1 pinned `windowed_median.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/probability/windowed_median.cpp)

[`workload.json`](workload.json) covers increasing and decreasing streams, odd and even windows, duplicates, negatives, partial windows, exact large values, maximum bounds, and invalid packing/domain values. All nine ports use the shared `i64_array_bytes_output` ABI, whose runner oracle emits one widened median value per stream prefix.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm windowed_median --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm windowed_median
```
