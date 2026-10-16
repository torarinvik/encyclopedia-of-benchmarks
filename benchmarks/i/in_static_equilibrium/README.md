# Static Torque Equilibrium

This benchmark follows the pinned Python predicate over planar force vectors and their application locations. It sums the scalar z-axis moments and checks whether the absolute total is below the source's default epsilon `0.1`.

## Contract

- The `i64_array_scalar` ABI packs `[n, force_x[n], force_y[n], location_x[n], location_y[n]]` as signed 64-bit integers. Require `1 <= n <= 100`, exact length `1 + 4*n`, and every vector component in `[-1000,1000]`.
- In input order, compute each moment as `location_x[i] * force_y[i] - location_y[i] * force_x[i]`, add the moments, and return `1` iff `abs(sum_moments) < 0.1`, else `0`. Because the supported inputs are integers, each moment and their sum are exact integers; this comparison is equivalent to testing for a zero total moment.
- This source checks torque balance only. It does not require the vector sum of forces to be zero. Null pointers, malformed layouts, or out-of-domain inputs return `-1`.

The bounds keep all products and sums safely within signed 64-bit integers and exactly representable in binary64. This differs from `equilibrium_index_in_array`, which searches a one-dimensional array for an index where prefix and suffix sums agree.

## Source

- [TheAlgorithms/Python `physics/in_static_equilibrium.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/in_static_equilibrium.py)

The pinned function computes `location[:, 0] * forces[:, 1] - location[:, 1] * forces[:, 0]`, sums those moments, and returns `bool(abs(sum_moments) < eps)` with `eps=10**-1`. This package fixes that default and represents the boolean as `1` or `0`.

## Workload

[`workload.json`](workload.json) covers zero and nonzero moments, cancellation between separate forces, torque balance despite nonzero net force, the strict threshold boundary over integer values, and malformed/domain-invalid inputs. The shared recorder checks the cases against an independent exact-integer torque-sum oracle, and the verifier adds exhaustive small vectors and bounded random cases.

Build, record, and verify an implementation with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm in_static_equilibrium --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/i/in_static_equilibrium/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms in_static_equilibrium --languages rust
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/i/in_static_equilibrium.c`](../../../c/i/in_static_equilibrium.c) |
| C3 | [`c3/i/in_static_equilibrium.c3`](../../../c3/i/in_static_equilibrium.c3) |
| C++ | [`cpp/i/in_static_equilibrium.cpp`](../../../cpp/i/in_static_equilibrium.cpp) |
| Elisa | [`elisa/i/in_static_equilibrium.elisa`](../../../elisa/i/in_static_equilibrium.elisa) |
| Nim | [`nim/i/in_static_equilibrium.nim`](../../../nim/i/in_static_equilibrium.nim) |
| Odin | [`odin/i/in_static_equilibrium.odin`](../../../odin/i/in_static_equilibrium.odin) |
| Rust | [`rust/i/in_static_equilibrium.rs`](../../../rust/i/in_static_equilibrium.rs) |
| V | [`v/i/in_static_equilibrium.v`](../../../v/i/in_static_equilibrium.v) |
| Zig | [`zig/i/in_static_equilibrium.zig`](../../../zig/i/in_static_equilibrium.zig) |
