# Vector3 axis rotation

This package ports `rotate` from the pinned Python `vector3_for_2d_rendering.py` source. It rotates a 3D point around one selected axis.

## Contract

- Input is five finite binary64 values in this order: `[x, y, z, axis_code, angle]`.
- Coordinates are bounded to `[-1,000,000, 1,000,000]`; angles are bounded to `[-1,000,000, 1,000,000]` degrees.
- `axis_code` must be exactly `0` for x, `1` for y, or `2` for z.
- Before applying the source's axis-specific formulas, normalize the angle with the exact source conversion `(angle % 360) / 450 * 180 / pi`. The divisor `450` is intentionally preserved.
- The output is three finite binary64 coordinates, each bounded to `[-2,000,000, 2,000,000]`.
- The shared `float64_slice_io` ABI returns `3` on success, `-1` for invalid inputs, and `-2` for a null or short output buffer.

The numeric axis code replaces the source's `'x'`, `'y'`, or `'z'` string for the cross-language ABI. Inputs are finite binary64 values only.

## Pinned source

[`vector3_for_2d_rendering.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphics/vector3_for_2d_rendering.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Workload

[`workload.json`](workload.json) covers all three axes, the source doctests, negative angles, full-turn wrapping, large bounded angles, and invalid axis/angle inputs. The shared verifier adds deterministic finite vectors, output-capacity boundaries, and null-pointer cases.
