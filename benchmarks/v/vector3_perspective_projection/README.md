# Vector3 perspective projection

This package ports `convert_to_2d` from the pinned Python `vector3_for_2d_rendering.py` source. It projects a 3D point into 2D using the source's perspective formula.

## Contract

- Input is five finite binary64 values in this order: `[x, y, z, scale, distance]`.
- Each input is bounded to `[-1,000,000, 1,000,000]`.
- The denominator `z + distance` must have magnitude at least `1e-6`; this excludes the singular source case `z == -distance` and values too close to that singularity for the benchmark's bounded domain.
- The output is `[projected_x, projected_y]`, where each component follows `((coordinate * distance) / (z + distance)) * scale` in that operation order. Output components are bounded to `[-1e25, 1e25]`.
- The shared `float64_slice_io` ABI returns `2` on success, `-1` for invalid inputs, and `-2` for a null or short output buffer.

These bounds keep valid calculations finite and avoid unstable division near the singularity while preserving the pinned formula. The original source also rejects nonnumeric arguments; this package's ABI accepts finite binary64 values only.

## Pinned source

[`vector3_for_2d_rendering.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphics/vector3_for_2d_rendering.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Workload

[`workload.json`](workload.json) covers the pinned doctest, positive and negative coordinates, zero and negative distance, large bounded values, the minimum denominator, and invalid/singular inputs. The shared verifier adds deterministic finite vectors, output-capacity boundaries, and null-pointer cases.
