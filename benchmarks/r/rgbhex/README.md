# Bidirectional RGB and packed hexadecimal conversion

Convert between an unsigned 32-bit packed color and three RGB channels using the pinned Go conversion pair. The benchmark returns a packed 24-bit color for both directions.

## Contract

The `i64_array_scalar` input is `[op, x, y, z]` with exactly four signed 64-bit values. The malformed-input corpus has a maximum length of five values. For `op = 0`, `x` is an unsigned 32-bit packed color in `0..=0xffffffff`, and `y = z = 0`; this applies `HEXToRGB`, then repacks the returned red, green, and blue bytes as `(red << 16) | (green << 8) | blue`. Consequently, only the low 24 bits remain in the result. For `op = 1`, `x`, `y`, and `z` are red, green, and blue channels in `0..=255`; this applies `RGBToHEX`. Invalid operations, lengths, ranges, or unused fields return `-1`.

The two operations match the pinned Go source’s bit shifts and masks. This is distinct from `hex_to_rgb`, which parses six ASCII hexadecimal digit codes.

## Sources

- Go [`rgbhex.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/conversion/rgbhex.go) exposes `HEXToRGB(uint)` and `RGBToHEX(byte, byte, byte)`. `HEXToRGB` extracts only bits 0–23; `RGBToHEX` packs the three byte channels.

## Workload and recording

[`workload.json`](workload.json) covers each operation, byte and uint32 boundaries, discarded high bits, malformed lengths, invalid operations, and invalid fields. The independent oracle returns the packed low-24-bit color or `-1`.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm rgbhex --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/r/rgbhex/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/r/rgbhex.c`](../../../c/r/rgbhex.c) |
| C3 | [`c3/r/rgbhex.c3`](../../../c3/r/rgbhex.c3) |
| C++ | [`cpp/r/rgbhex.cpp`](../../../cpp/r/rgbhex.cpp) |
| Elisa | [`elisa/r/rgbhex.elisa`](../../../elisa/r/rgbhex.elisa) |
| Nim | [`nim/r/rgbhex.nim`](../../../nim/r/rgbhex.nim) |
| Odin | [`odin/r/rgbhex.odin`](../../../odin/r/rgbhex.odin) |
| Rust | [`rust/r/rgbhex.rs`](../../../rust/r/rgbhex.rs) |
| V | [`v/r/rgbhex.v`](../../../v/r/rgbhex.v) |
| Zig | [`zig/r/rgbhex.zig`](../../../zig/r/rgbhex.zig) |
