# Bisection 2

This benchmark ports the pinned Python `bisection_2` routine for the fixed equation `f(x) = 10 - x*x`. It bisects a valid sign-changing interval until its width is below `0.01`, updating the endpoint on the same side as the source.

## Contract

The `i64_array_float64` ABI accepts exactly `[left_milli, right_milli]`, where each endpoint is the corresponding real value divided by 1,000 and is bounded to `[-100, 100]`. The left endpoint must be less than the right endpoint, and `f(left) * f(right)` must be negative. The result is the source variable `c` as a binary64 value. Invalid shape, bounds, ordering, or a non-bracketing interval returns `-1e300`.

The source initializes `c` to the left endpoint before the loop. When a valid interval is already narrower than `0.01`, it returns that left endpoint without taking a midpoint. The workload includes this behavior, the source examples, positive and negative roots, and invalid intervals.

The `i64_array_float64` runner validates the endpoint bounds and sign-changing bracket, then checks the exact source-ordered midpoint updates.

## Source and workload

[`workload.json`](workload.json) defines the bounded millipoint contract and uses relative and absolute tolerances of `1e-12`.

- Python [`bisection_2.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/bisection_2.py)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm bisection_2 --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/b/bisection_2/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/b/bisection_2.c`](../../../c/b/bisection_2.c) |
| C3 | [`c3/b/bisection_2.c3`](../../../c3/b/bisection_2.c3) |
| C++ | [`cpp/b/bisection_2.cpp`](../../../cpp/b/bisection_2.cpp) |
| Elisa | [`elisa/b/bisection_2.elisa`](../../../elisa/b/bisection_2.elisa) |
| Nim | [`nim/b/bisection_2.nim`](../../../nim/b/bisection_2.nim) |
| Odin | [`odin/b/bisection_2.odin`](../../../odin/b/bisection_2.odin) |
| Rust | [`rust/b/bisection_2.rs`](../../../rust/b/bisection_2.rs) |
| V | [`v/b/bisection_2.v`](../../../v/b/bisection_2.v) |
| Zig | [`zig/b/bisection_2.zig`](../../../zig/b/bisection_2.zig) |
