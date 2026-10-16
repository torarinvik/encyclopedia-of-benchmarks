# Newton–Raphson method

## Contract

Apply Newton–Raphson to the pinned cubic equation `f(x)=x^3-4x-9`, whose derivative is `f'(x)=3x^2-4`. Packed input is `[x0_milli, iteration_limit]`: the initial guess is `x0_milli / 1000` in 2..4, and `iteration_limit` caps the loop at 1..32 updates.

Each update follows the source order: save `m=f(c)` and `n=f'(c)`, compute `z=c-m/n`, assign `c=z`, then stop if the saved `abs(m)` is below `1e-10`. If the cap is reached first, return the last `z`. The bounded start interval keeps the derivative nonzero and the iterates finite. The benchmark supplies a deterministic initial guess in place of the CLI's time-seeded random guess. Invalid input returns `-1e300`.

## Workload

Cases and expected values are in [`workload.json`](workload.json). The package uses the `i64_array_float64` scalar ABI with absolute tolerance `1e-10`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/newton_raphson_method.c`](../../../c/n/newton_raphson_method.c) |
| C3 | [`c3/n/newton_raphson_method.c3`](../../../c3/n/newton_raphson_method.c3) |
| C++ | [`cpp/n/newton_raphson_method.cpp`](../../../cpp/n/newton_raphson_method.cpp) |
| Elisa | [`elisa/n/newton_raphson_method.elisa`](../../../elisa/n/newton_raphson_method.elisa) |
| Nim | [`nim/n/newton_raphson_method.nim`](../../../nim/n/newton_raphson_method.nim) |
| Odin | [`odin/n/newton_raphson_method.odin`](../../../odin/n/newton_raphson_method.odin) |
| Rust | [`rust/n/newton_raphson_method.rs`](../../../rust/n/newton_raphson_method.rs) |
| V | [`v/n/newton_raphson_method.v`](../../../v/n/newton_raphson_method.v) |
| Zig | [`zig/n/newton_raphson_method.zig`](../../../zig/n/newton_raphson_method.zig) |

## TheAlgorithms references

- [C++ `newton_raphson_method.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/newton_raphson_method.cpp)
- [C++-1 `newton_raphson_method.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/newton_raphson_method.cpp)

## Source scope

This benchmark follows the pinned C++ implementations. The pinned [R `newton_raphson_method.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/newton_raphson_method.r) is a generic routine that accepts caller-provided `f` and `fprime`, takes a configurable tolerance and iteration count, and stops when the step size is below tolerance. Those APIs, derivatives, and stopping rules differ from this fixed cubic benchmark, which uses a saved residual threshold. The Python, R, and Rust sources are tracked separately under the generic `newton_raphson` candidate.
