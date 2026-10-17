# Quaternions

This benchmark covers the three quaternion routines in the pinned C source:
Euler-to-quaternion conversion, quaternion-to-Euler conversion, and Hamilton
product. It preserves the source's binary32 fields and arithmetic even though
the benchmark ABI transports inputs and outputs as binary64 values.

## Input and output

Every input starts with an exact operation selector:

- `0`: `[0, yaw, pitch, roll]` in radians; assign the values by name to the C
  `euler` fields, then return `[w, q1, q2, q3]`.
- `1`: `[1, w, q1, q2, q3]`; returns `[roll, pitch, yaw]` in radians.
- `2`: `[2, aw, a1, a2, a3, bw, b1, b2, b3]`; returns the scalar-first
  Hamilton product `[w, q1, q2, q3]`.

Input values are first checked as finite binary64 values. The operation
selector must be exactly `0`, `1`, or `2`. Euler angles are bounded to
`[-3, 3]` radians before conversion to binary32. For operation 1, quaternion
components are rounded to binary32 before the `[-1, 1]` bound and normalization
checks. For operation 2, each binary64 component must be in `[-1, 1]` before it
is rounded to binary32; product inputs need not be normalized.

For operation 1, the rounded binary32 quaternion must have squared norm within
`1e-6` of one, using binary32 sum/product steps. The source's pitch argument
`2 * (w*q2 + q1*q3)` is computed in binary32 and must be in `[-1, 1]`, since
the pinned implementation passes it directly to `asinf` without clamping.
The executable source uses the **plus** sign in this pitch expression; its
nearby Doxygen equation has a different sign.

Operation 2 bounds each input component in binary64 to `[-1, 1]` before
rounding to binary32. Its four Hamilton product components are bounded to
`[-4, 4]`.

Output elements are widened binary32 results. Operations 0 and 2 write four
elements; operation 1 writes three. Invalid input returns `-1`; null or
insufficient output capacity returns `-2`. Validate input before output
availability, and leave the output unchanged on errors. The workspace holds
four binary64 elements. Results are compared with absolute tolerance `1e-6`
and zero relative tolerance.

## Workload and oracle

[`workload.json`](workload.json) exercises each operation, angle and component
bounds, the quaternion normalization and pitch-domain restrictions, plus-sign
pitch behavior, and non-commutative multiplication. Output-buffer probes are
listed in the workload's `abi_cases`. The
independent binary32 oracle is
[`benchmarks/quaternions_oracle.py`](../../quaternions_oracle.py).

## Reviewed source

- [TheAlgorithms/C `geometry/quaternions.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/geometry/quaternions.c)
- [TheAlgorithms/C `geometry/geometry_datatypes.h`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/geometry/geometry_datatypes.h)

## Build and record

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm quaternions --language rust
python3 benchmarks/run_float64_slice_io.py --build-manifest build/float64_slice_io/q/quaternions/rust/build.json
python3 benchmarks/verify_float64_slice_io.py --algorithm quaternions
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/q/quaternions.c`](../../../c/q/quaternions.c) |
| C3 | [`c3/q/quaternions.c3`](../../../c3/q/quaternions.c3) |
| C++ | [`cpp/q/quaternions.cpp`](../../../cpp/q/quaternions.cpp) |
| Elisa | [`elisa/q/quaternions.elisa`](../../../elisa/q/quaternions.elisa) |
| Nim | [`nim/q/quaternions.nim`](../../../nim/q/quaternions.nim) |
| Odin | [`odin/q/quaternions.odin`](../../../odin/q/quaternions.odin) |
| Rust | [`rust/q/quaternions.rs`](../../../rust/q/quaternions.rs) |
| V | [`v/q/quaternions.v`](../../../v/q/quaternions.v) |
| Zig | [`zig/q/quaternions.zig`](../../../zig/q/quaternions.zig) |
