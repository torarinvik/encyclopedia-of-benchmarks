# Largest rectangle in a histogram

Given bar heights with unit width, return the area of the largest rectangle spanning a contiguous range of bars. The implementations use a monotone stack to find the widest range for each limiting bar.

## Contract

- Input is an array of signed 64-bit heights with length 0 through 64.
- Each height is in `[0, 1,000,000]`. The largest possible area is 64,000,000, so it fits the Java source's signed 32-bit arithmetic and decimal-string result.
- Return the largest rectangle area as an integer. Empty input returns zero, matching both pinned sources.
- Overlength or negative/out-of-range heights return `INT64_MIN`, outside the valid result range.

The Java source returns the area as decimal text; this benchmark normalizes that value to the shared integer result. The Python source returns an integer directly. The two candidates use the same monotone-stack histogram algorithm and are represented by this one contract.

## Workload and oracle

[`workload.json`](workload.json) covers empty and zero-height inputs, the pinned examples, equal/increasing/decreasing bars, separated histograms, maximum length/height, and malformed inputs. The independent quadratic oracle is [`largest_rectangle_histogram_oracle.py`](../../largest_rectangle_histogram_oracle.py).

## Reviewed source implementations

- [TheAlgorithms/Java `LargestRectangle.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/LargestRectangle.java)
- [TheAlgorithms/Python `largest_rectangle_histogram.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/largest_rectangle_histogram.py)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm largest_rectangle_histogram --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm largest_rectangle_histogram
python3 benchmarks/verify_i64_array_scalar.py --algorithm largest_rectangle_histogram
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/largest_rectangle_histogram.c`](../../../c/l/largest_rectangle_histogram.c) |
| C3 | [`c3/l/largest_rectangle_histogram.c3`](../../../c3/l/largest_rectangle_histogram.c3) |
| C++ | [`cpp/l/largest_rectangle_histogram.cpp`](../../../cpp/l/largest_rectangle_histogram.cpp) |
| Elisa | [`elisa/l/largest_rectangle_histogram.elisa`](../../../elisa/l/largest_rectangle_histogram.elisa) |
| Nim | [`nim/l/largest_rectangle_histogram.nim`](../../../nim/l/largest_rectangle_histogram.nim) |
| Odin | [`odin/l/largest_rectangle_histogram.odin`](../../../odin/l/largest_rectangle_histogram.odin) |
| Rust | [`rust/l/largest_rectangle_histogram.rs`](../../../rust/l/largest_rectangle_histogram.rs) |
| V | [`v/l/largest_rectangle_histogram.v`](../../../v/l/largest_rectangle_histogram.v) |
| Zig | [`zig/l/largest_rectangle_histogram.zig`](../../../zig/l/largest_rectangle_histogram.zig) |
