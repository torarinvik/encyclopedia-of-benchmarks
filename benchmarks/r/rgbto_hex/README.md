# RGB to hexadecimal

Format three RGB channels as a seven-byte lowercase hexadecimal color string, including the leading `#`. This follows the pinned JavaScript `RGBToHex` function on integer channel values from 0 through 255.

## Contract

- The `i64_array_bytes_output` input contains exactly three signed 64-bit values: red, green, and blue, each in `0..255`.
- Output is `#rrggbb`, with two lowercase hexadecimal digits per channel and leading zeroes preserved.
- Wrong input length or an out-of-range channel returns `-1` without writing output.
- Insufficient output capacity or a null output pointer returns `-2` without writing output.
- Successful calls write exactly 7 ASCII bytes and return 7.

The JavaScript source accepts general numbers and uses JavaScript hexadecimal formatting. This bounded contract selects integer byte channels so the output is exactly two digits per channel.

## Workload and oracle

[`workload.json`](workload.json) covers black, white, source examples, leading zeroes, channel boundaries, malformed shapes and values, and insufficient capacity. The independent oracle is [`rgbto_hex_oracle.py`](../../rgbto_hex_oracle.py).

Pinned source: [TheAlgorithms/JavaScript `RGBToHex.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/RGBToHex.js).

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm rgbto_hex --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm rgbto_hex
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm rgbto_hex
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rgbto_hex.c`](../../../c/r/rgbto_hex.c) |
| C3 | [`c3/r/rgbto_hex.c3`](../../../c3/r/rgbto_hex.c3) |
| C++ | [`cpp/r/rgbto_hex.cpp`](../../../cpp/r/rgbto_hex.cpp) |
| Elisa | [`elisa/r/rgbto_hex.elisa`](../../../elisa/r/rgbto_hex.elisa) |
| Nim | [`nim/r/rgbto_hex.nim`](../../../nim/r/rgbto_hex.nim) |
| Odin | [`odin/r/rgbto_hex.odin`](../../../odin/r/rgbto_hex.odin) |
| Rust | [`rust/r/rgbto_hex.rs`](../../../rust/r/rgbto_hex.rs) |
| V | [`v/r/rgbto_hex.v`](../../../v/r/rgbto_hex.v) |
| Zig | [`zig/r/rgbto_hex.zig`](../../../zig/r/rgbto_hex.zig) |
