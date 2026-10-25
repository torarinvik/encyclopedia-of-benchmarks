# Embench depthconv

This package is a clean-room bounded profile of the TensorFlow Lite Micro DepthwiseConvPerChannel kernel used by Embench-IoT. It preserves its quantized int8 arithmetic, per-channel output multiplier and shift, bias addition, and final int8 activation clamp. It is distinct from general convolution and relaxed/online convolution.

## Contract

Export depthconv with the i64_array_bytes_output ABI. Input is `[channels, input[4 rows][channels], filter[4 rows][channels], bias[channels], multiplier[channels], shift[channels]]`. This is the source's one-batch NHWC shape `[1,4,1,channels]`, filter `[1,4,1,channels]`, and valid output `[1,1,1,channels]`, with depth multiplier 1, stride and dilation 1, and no padding. Channels are 1 through 8. Input and filter values are signed int8 values `-128..127`; bias is bounded to `-1,000,000..1,000,000`; each quantized multiplier is `0..2^31-1`; each per-channel shift is `-8..0`. Exact input length is `1+11*channels` (maximum 89).

For each channel the accumulator starts at zero and adds `filter[y,channel] * (input[y,channel] + 128)` for y=0..3, then adds bias. The quantized multiplier step follows the source formula: `total_shift=31-shift`, `round=1<<(total_shift-1)`, and floor-arithmetic-shift `(acc*multiplier+round)` by `total_shift`. This explicitly models the source's usual two's-complement arithmetic right shift for negative intermediate results. Output offset is 0 and activation bounds are `[-128,127]`; output is one byte per channel containing the two's-complement representation of the signed result. Malformed input returns `-1` before output checks; null output or capacity below channels returns `-2` without writes; success returns the channel count.

The multiplier/shift, bias, and channel bounds keep all source-style int32 accumulations and the int64 multiplier intermediate in range. The source's default input offset, output offset, activation bounds, depth multiplier, stride, dilation, and padding are fixed in this profile.

## Provenance and rights

- Repository: [embench/embench-iot](https://github.com/embench/embench-iot)
- Commit: `09c2ed8c3b7008c95d08b038de4a3f6dc103ed70`
- Source: [`src/depthconv/depthconv.c`](https://github.com/embench/embench-iot/blob/09c2ed8c3b7008c95d08b038de4a3f6dc103ed70/src/depthconv/depthconv.c), function `DepthwiseConvPerChannel`.
- The source header identifies Copyright 2024 The TensorFlow Authors and SPDX Apache-2.0. The complete Apache 2.0 license is in [`LICENSE.txt`](LICENSE.txt), and attribution/provenance is in [`NOTICE.txt`](NOTICE.txt).

[`workload.json`](workload.json) records the pin, profile bounds, and byte-output fixtures. [`depthconv_oracle.py`](../../depthconv_oracle.py) is an independent integer-arithmetic oracle.

| Language | Port |
|---|---|
| C | [`c/d/depthconv.c`](../../../c/d/depthconv.c) |
| C3 | [`c3/d/depthconv.c3`](../../../c3/d/depthconv.c3) |
| C++ | [`cpp/d/depthconv.cpp`](../../../cpp/d/depthconv.cpp) |
| Elisa | [`elisa/d/depthconv.elisa`](../../../elisa/d/depthconv.elisa) |
| Nim | [`nim/d/depthconv.nim`](../../../nim/d/depthconv.nim) |
| Odin | [`odin/d/depthconv.odin`](../../../odin/d/depthconv.odin) |
| Rust | [`rust/d/depthconv.rs`](../../../rust/d/depthconv.rs) |
| V | [`v/d/depthconv.v`](../../../v/d/depthconv.v) |
| Zig | [`zig/d/depthconv.zig`](../../../zig/d/depthconv.zig) |

No runtime or compiler verification is claimed.
