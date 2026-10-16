# Project Euler Problem 144: Investigating Multiple Reflections of a Laser Beam

## Contract

The `float64_pair` function accepts the first impact point `(x, y)` on the ellipse `4x² + y² = 100`. Inputs must be finite and satisfy `1e-5 <= x <= 5`, `-10 <= y <= 0`, and `abs(4x² + y² - 100) <= 1e-6`. It returns the number of source `next_point` transitions until the beam reaches the exit aperture `abs(x) <= 0.01` with `y > 0`. Invalid inputs return `-1e300`.

The ports preserve the source's tangent-normal reflection calculation, quadratic intersection, and `isclose`-based choice of the root that is not the current impact point. To bound the adapter for unsupported trajectories, it returns the invalid sentinel if the aperture is not reached within 10,000 transitions. The result is an exactly representable integer stored as binary64.

The pinned source's default point `(1.4, -9.6)` returns **354**; its examples `(0.00001, -10)` and `(5, 0)` return **1** and **287**.

## Workload

[`workload.json`](workload.json) covers the default point, both source examples, a zero-x division guard, an off-ellipse point, and a point outside the supported quadrant. It uses the `float64_pair` ABI.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_144/sol1.py)

## Build and run

Build the Rust port with:

    python3 benchmarks/build_abi.py --family float64_pair --algorithm problem144 --language rust

Run it with:

    python3 benchmarks/run_float64_pair.py --build-manifest build/float64_pair/p/problem144/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem144.c](../../../c/p/problem144.c) |
| C3 | [c3/p/problem144.c3](../../../c3/p/problem144.c3) |
| C++ | [cpp/p/problem144.cpp](../../../cpp/p/problem144.cpp) |
| Elisa | [elisa/p/problem144.elisa](../../../elisa/p/problem144.elisa) |
| Nim | [nim/p/problem144.nim](../../../nim/p/problem144.nim) |
| Odin | [odin/p/problem144.odin](../../../odin/p/problem144.odin) |
| Rust | [rust/p/problem144.rs](../../../rust/p/problem144.rs) |
| V | [v/p/problem144.v](../../../v/p/problem144.v) |
| Zig | [zig/p/problem144.zig](../../../zig/p/problem144.zig) |
