# Koch Snowflake Point Iteration

Apply the pinned iterative Koch construction to an ordered list of 2D points. Each segment becomes four segments by adding two trisection points and a third point formed from a +60-degree rotation of the first third.

## Contract

- ABI: `float64_slice_io`.
- Input is `[steps, point_count, x0, y0, ..., x_(n-1), y_(n-1)]`, with exact length `2 + 2*point_count`, `2 <= point_count <= 8`, and `0 <= steps <= 1`.
- Coordinates must be finite and lie in `[-1000, 1000]`. Each input coordinate is converted to binary32 before iteration, matching the pinned C# `Vector2` precision.
- Invalid framing, point count, step count, or coordinate returns `-1`.
- Preserve input point order. The result contains `(point_count-1)*4^steps+1` points, returned as alternating x/y coordinates widened from binary32 to binary64. The output workspace holds 58 coordinates.
- The runner compares output coordinates with absolute tolerance `1e-6` and relative tolerance `1e-7`. Ports round every vector addition, subtraction, multiplication, and division to binary32 in the pinned operation order, then widen outputs to binary64. The rotation coefficients are the binary32 results of the source expression `60f * (float)Math.PI / 180` followed by its cosine and sine calls. Rendering is excluded.

## Workload

[`workload.json`](workload.json) covers zero and one iteration, reversed and multiple segments, repeated points, fractional and negative coordinates, maximum point/output sizes, malformed frames, and numeric bounds. See the [oracle](../../koch_snowflake_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/koch_snowflake.c`](../../../c/k/koch_snowflake.c) |
| C3 | [`c3/k/koch_snowflake.c3`](../../../c3/k/koch_snowflake.c3) |
| C++ | [`cpp/k/koch_snowflake.cpp`](../../../cpp/k/koch_snowflake.cpp) |
| Elisa | [`elisa/k/koch_snowflake.elisa`](../../../elisa/k/koch_snowflake.elisa) |
| Nim | [`nim/k/koch_snowflake.nim`](../../../nim/k/koch_snowflake.nim) |
| Odin | [`odin/k/koch_snowflake.odin`](../../../odin/k/koch_snowflake.odin) |
| Rust | [`rust/k/koch_snowflake.rs`](../../../rust/k/koch_snowflake.rs) |
| V | [`v/k/koch_snowflake.v`](../../../v/k/koch_snowflake.v) |
| Zig | [`zig/k/koch_snowflake.zig`](../../../zig/k/koch_snowflake.zig) |

## Pinned sources

- [TheAlgorithms/C-Sharp `KochSnowflake.Iterate`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/KochSnowflake.cs) at `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`.
- [TheAlgorithms/Java `KochSnowflake.iterate`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/KochSnowflake.java) at `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.
- [TheAlgorithms/JavaScript `iterate`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Recursive/KochSnowflake.js) at `5c39e87a9a31f279c60f830ad74a845e4788a517`.
- [TheAlgorithms/Python `iterate`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fractals/koch_snowflake.py) at `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Build and record

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm koch_snowflake --language rust
python3 benchmarks/run_float64_slice_io.py --algorithm koch_snowflake
```
