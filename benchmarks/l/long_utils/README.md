# LongUtils 64-Bit Rotations

Rotate a 64-bit word left or right using one of the pinned signed or unsigned overloads. Every operation preserves the same 64-bit pattern; signedness selects the source overload and the result is returned as raw little-endian bytes.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[operation, value_bits, distance]`, with exact length 3. Operation codes 0–3 select signed-left, unsigned-left, signed-right, and unsigned-right rotation.
- `value_bits` is any signed 64-bit input word. `distance` must be in `0..63`; invalid operation, distance, or framing returns `-1` before output storage is checked.
- Return the rotated 64-bit bit pattern in 8 little-endian bytes. Signed results preserve the source cast back to `long`; unsigned results preserve the `ulong` bits.
- Null output or capacity below 8 returns `-2` without writes. Exact capacity succeeds.

The ports reinterpret the input word as unsigned bits, perform the circular shift, and serialize the result. Distance zero returns the original bit pattern without shifting by the word width.

## Workload

[`workload.json`](workload.json) covers all four overloads, zero/one/63-bit rotations, high-bit and all-one patterns, malformed inputs, null output, and capacity boundaries. See the [oracle](../../long_utils_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/long_utils.c`](../../../c/l/long_utils.c) |
| C3 | [`c3/l/long_utils.c3`](../../../c3/l/long_utils.c3) |
| C++ | [`cpp/l/long_utils.cpp`](../../../cpp/l/long_utils.cpp) |
| Elisa | [`elisa/l/long_utils.elisa`](../../../elisa/l/long_utils.elisa) |
| Nim | [`nim/l/long_utils.nim`](../../../nim/l/long_utils.nim) |
| Odin | [`odin/l/long_utils.odin`](../../../odin/l/long_utils.odin) |
| Rust | [`rust/l/long_utils.rs`](../../../rust/l/long_utils.rs) |
| V | [`v/l/long_utils.v`](../../../v/l/long_utils.v) |
| Zig | [`zig/l/long_utils.zig`](../../../zig/l/long_utils.zig) |

## Pinned source

- [TheAlgorithms/C-Sharp `LongUtils`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Crypto/Utils/LongUtils.cs) at `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`.

The benchmark covers `RotateLeft(long, int)`, `RotateLeft(ulong, int)`, `RotateRight(long, int)`, and `RotateRight(ulong, int)`. Inputs with distances outside `0..63` are outside the bounded domain even though the framework operation masks the shift distance.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm long_utils --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/l/long_utils/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm long_utils
```
