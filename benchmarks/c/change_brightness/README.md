# Change brightness

The pinned Python function applies a PIL point transform using `128 + level + (channel - 128)`, which simplifies to adding the level to every image channel. It accepts levels from -255.0 through 255.0. This portable contract covers whole-number levels in that range and channel bytes from 0 through 255.

## Contract

- The `i64_array_bytes_output` ABI accepts `[level, channel_byte...]` with 1 through 4,096 signed 64-bit values. The first value must be in `[-255, 255]`; remaining values must be bytes.
- Each output byte is `clip(channel + level, 0, 255)`. The input channels are a flat sequence, so image loading, color mode selection, and file encoding are outside the benchmark.
- An input with only a level is valid and returns zero output bytes. Invalid inputs return `-1`; insufficient output capacity returns `-2` without writing.
- The maximum output is 4,095 bytes.

[`workload.json`](workload.json) covers both clipping boundaries, the full minimum and maximum levels, invalid inputs, empty images, and insufficient capacity. The verifier checks all 256 channel bytes for each of the 511 legal levels. All nine ports passed 529 oracle inputs and 12 workload cases.

```sh
python3.12 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm change_brightness --language rust
python3.12 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/change_brightness/rust/build.json
python3.12 benchmarks/verify_i64_array_bytes_output.py --algorithm change_brightness
```

| Language | Source |
| --- | --- |
| C | [`c/c/change_brightness.c`](../../../c/c/change_brightness.c) |
| C3 | [`c3/c/change_brightness.c3`](../../../c3/c/change_brightness.c3) |
| C++ | [`cpp/c/change_brightness.cpp`](../../../cpp/c/change_brightness.cpp) |
| Elisa | [`elisa/c/change_brightness.elisa`](../../../elisa/c/change_brightness.elisa) |
| Nim | [`nim/c/change_brightness.nim`](../../../nim/c/change_brightness.nim) |
| Odin | [`odin/c/change_brightness.odin`](../../../odin/c/change_brightness.odin) |
| Rust | [`rust/c/change_brightness.rs`](../../../rust/c/change_brightness.rs) |
| V | [`v/c/change_brightness.v`](../../../v/c/change_brightness.v) |
| Zig | [`zig/c/change_brightness.zig`](../../../zig/c/change_brightness.zig) |

## TheAlgorithms reference

- [Python `change_brightness.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/change_brightness.py)
