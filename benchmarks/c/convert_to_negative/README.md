# Convert to negative

The pinned Python function mutates an OpenCV color image in place by replacing each channel with `255 - channel`, then returns that same image. This benchmark returns the transformed channel bytes in row-major order; since each output depends only on the corresponding byte, the transform is identical regardless of image dimensions or channel grouping.

## Contract

- The `i64_array_bytes_output` ABI accepts `[channel_count, channel_0, ..., channel_(n-1)]`. The count is from 0 through 4,095 and must match the number of remaining values. Each channel must be a byte.
- Output contains `255 - channel` for each input channel, in input order.
- Invalid input returns `-1`; insufficient output capacity returns `-2` without writing. A successful call returns the number of output bytes, up to 4,095.

[`workload.json`](workload.json) covers the complete byte range, empty and maximum-size vectors, malformed counts and channels, and insufficient capacity. The verifier checked 17 oracle inputs and all eight workload cases; all nine ports passed.

```sh
python3.12 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm convert_to_negative --language rust
python3.12 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/convert_to_negative/rust/build.json
python3.12 benchmarks/verify_i64_array_bytes_output.py --algorithm convert_to_negative
```

| Language | Source |
| --- | --- |
| C | [`c/c/convert_to_negative.c`](../../../c/c/convert_to_negative.c) |
| C3 | [`c3/c/convert_to_negative.c3`](../../../c3/c/convert_to_negative.c3) |
| C++ | [`cpp/c/convert_to_negative.cpp`](../../../cpp/c/convert_to_negative.cpp) |
| Elisa | [`elisa/c/convert_to_negative.elisa`](../../../elisa/c/convert_to_negative.elisa) |
| Nim | [`nim/c/convert_to_negative.nim`](../../../nim/c/convert_to_negative.nim) |
| Odin | [`odin/c/convert_to_negative.odin`](../../../odin/c/convert_to_negative.odin) |
| Rust | [`rust/c/convert_to_negative.rs`](../../../rust/c/convert_to_negative.rs) |
| V | [`v/c/convert_to_negative.v`](../../../v/c/convert_to_negative.v) |
| Zig | [`zig/c/convert_to_negative.zig`](../../../zig/c/convert_to_negative.zig) |

## TheAlgorithms reference

- [Python `convert_to_negative.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/convert_to_negative.py)
