# Solve a quadratic equation with the p-q formula

Solve `x² + p*x + q = 0` using the pinned Lua function. The function returns no values for a negative radicand, one value when both computed roots are equal, and two values otherwise.

## Contract

- Input is exactly `[p, q]`, both signed 64-bit integers in `[-1,000,000, 1,000,000]`.
- Compute `root = sqrt(p²/4 - q)`, then `x1 = -p/2 - root` and `x2 = -p/2 + root`. Emit roots in that order. If `x1 == x2`, emit only `x1`.
- Output is a vector of little-endian IEEE-754 binary64 values. Return the number of emitted roots: 0, 1, or 2. Negative radicands therefore succeed with no output bytes, including when the output pointer is null and capacity is zero.
- Invalid input returns `-1`. A null or short output buffer returns `-2` when one or two roots need to be written. One root needs 8 bytes; two roots need 16.
- Integer coefficients make `p²` exact in binary64 at these bounds, and the computed roots remain finite. Comparison uses absolute and relative tolerance `1e-12`.

The root order is the pinned Lua return order (minus square root, then plus square root). This differs from the plus-first `quadratic_roots` package and the existing complex-root component solver, so it has a distinct benchmark contract.

## Workload and oracle

[`workload.json`](workload.json) covers negative, zero, and positive radicands; repeated, fractional, irrational, positive, and negative roots; coefficient limits; malformed input; and insufficient capacity.

Build and record with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm solve_quadratic_equation --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/solve_quadratic_equation/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm solve_quadratic_equation --language rust
```

## Pinned source

[TheAlgorithms/Lua `solve_quadratic_equation.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/solve_quadratic_equation.lua)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/solve_quadratic_equation.c`](../../../c/s/solve_quadratic_equation.c) |
| C3 | [`c3/s/solve_quadratic_equation.c3`](../../../c3/s/solve_quadratic_equation.c3) |
| C++ | [`cpp/s/solve_quadratic_equation.cpp`](../../../cpp/s/solve_quadratic_equation.cpp) |
| Elisa | [`elisa/s/solve_quadratic_equation.elisa`](../../../elisa/s/solve_quadratic_equation.elisa) |
| Nim | [`nim/s/solve_quadratic_equation.nim`](../../../nim/s/solve_quadratic_equation.nim) |
| Odin | [`odin/s/solve_quadratic_equation.odin`](../../../odin/s/solve_quadratic_equation.odin) |
| Rust | [`rust/s/solve_quadratic_equation.rs`](../../../rust/s/solve_quadratic_equation.rs) |
| V | [`v/s/solve_quadratic_equation.v`](../../../v/s/solve_quadratic_equation.v) |
| Zig | [`zig/s/solve_quadratic_equation.zig`](../../../zig/s/solve_quadratic_equation.zig) |

The independent oracle is [`solve_quadratic_equation_oracle.py`](../../solve_quadratic_equation_oracle.py).
