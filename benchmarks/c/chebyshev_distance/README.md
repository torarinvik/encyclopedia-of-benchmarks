# Chebyshev distance

## Contract

The pinned Python function accepts two equally sized coordinate lists and
returns `max(abs(a - b) for a, b in zip(point_a, point_b))`. This is the
largest coordinate difference across the points.

The shared `i64_array_scalar` ABI represents each call as
`[dimension, point_a..., point_b...]`. The dimension must be in `1..=128`,
the input length must be exactly `1 + 2 * dimension`, and each coordinate
must be a signed integer in `[-1,000,000,000, 1,000,000,000]`. Valid inputs
return the maximum absolute coordinate difference. Empty, malformed,
out-of-range, or over-dimension inputs return `-1`. This contract uses the
integer-coordinate subset of Python's float-list input so each result is
exact and bounded by `2,000,000,000`.

The packed format preserves equal dimensions by construction; malformed
lengths map to `-1` instead of the source's `ValueError` for mismatched point
lengths. Zero-dimensional points are excluded because the source's `max`
over an empty generator raises an error.

## Workload and build

[`workload.json`](workload.json) covers equal points, one and multiple
dimensions, negative coordinates, malformed lengths, and invalid bounds.
It uses the `i64_array_scalar` ABI family.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm chebyshev_distance --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/chebyshev_distance/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/c/chebyshev_distance.c`](../../../c/c/chebyshev_distance.c) |
| C3 | [`c3/c/chebyshev_distance.c3`](../../../c3/c/chebyshev_distance.c3) |
| C++ | [`cpp/c/chebyshev_distance.cpp`](../../../cpp/c/chebyshev_distance.cpp) |
| Elisa | [`elisa/c/chebyshev_distance.elisa`](../../../elisa/c/chebyshev_distance.elisa) |
| Nim | [`nim/c/chebyshev_distance.nim`](../../../nim/c/chebyshev_distance.nim) |
| Odin | [`odin/c/chebyshev_distance.odin`](../../../odin/c/chebyshev_distance.odin) |
| Rust | [`rust/c/chebyshev_distance.rs`](../../../rust/c/chebyshev_distance.rs) |
| V | [`v/c/chebyshev_distance.v`](../../../v/c/chebyshev_distance.v) |
| Zig | [`zig/c/chebyshev_distance.zig`](../../../zig/c/chebyshev_distance.zig) |

## Pinned source

- [Python `chebyshev_distance.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/chebyshev_distance.py)
