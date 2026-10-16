# Compress Consecutive Runs

Compress a sequence by retaining the first value of each run of adjacent equal values. The order of the remaining values stays unchanged.

## Contract

- Pack the `i64_array_bytes_output` input as `[n, values...]`. The length `n` is from 0 through 64, and the packed input length must equal `n+1`.
- Each value must fit a signed 32-bit integer. Empty input is valid and produces an empty output.
- Emit one copy of each value at the start of a consecutive equal-value run, as little-endian signed 32-bit integers. Return the number of values written.
- Invalid packing or values return `-1`. Output capacity must hold up to `4*n` bytes; insufficient capacity returns `-2`. The maximum output workspace is 256 bytes.

## Source and workload

The pinned Clojure source defines three implementations, `compress-1`, `compress-2`, and `compress-3`. Each keeps the first value in every adjacent-equal run. This bounded integer domain excludes `nil`, which the first two variants use as their initial previous-value sentinel.

- [TheAlgorithms/Clojure `compress.clj`](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/compress.clj)

[`workload.json`](workload.json) covers empty and singleton inputs, repeated runs, non-adjacent repeated values, signed 32-bit boundaries, maximum-size output, malformed packing, invalid values, and insufficient capacity. [`compress_oracle.py`](../../compress_oracle.py) computes adjacent-run compression independently.

Build and verify with the shared byte-output ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm compress --language rust
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm compress
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/c/compress.c`](../../../c/c/compress.c) |
| C3 | [`c3/c/compress.c3`](../../../c3/c/compress.c3) |
| C++ | [`cpp/c/compress.cpp`](../../../cpp/c/compress.cpp) |
| Elisa | [`elisa/c/compress.elisa`](../../../elisa/c/compress.elisa) |
| Nim | [`nim/c/compress.nim`](../../../nim/c/compress.nim) |
| Odin | [`odin/c/compress.odin`](../../../odin/c/compress.odin) |
| Rust | [`rust/c/compress.rs`](../../../rust/c/compress.rs) |
| V | [`v/c/compress.v`](../../../v/c/compress.v) |
| Zig | [`zig/c/compress.zig`](../../../zig/c/compress.zig) |
