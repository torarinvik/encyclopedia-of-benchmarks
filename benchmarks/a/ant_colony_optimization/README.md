# Ant Colony Optimization

This package benchmarks the pinned [TheAlgorithms/Rust implementation](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/ant_colony_optimization.rs), which applies ant colony optimization to the travelling-salesperson problem. The benchmark returns the best closed-tour distance.

The `i64_array_float64` input is `[num_ants, num_iterations, x0, y0, x1, y1, x2, y2]`. It uses exactly three distinct integer-coordinate cities, with each coordinate in `[-100,000, 100,000]`, 1–64 ants, and 1–64 iterations. The source's documented defaults are used: evaporation `0.7`, pheromone influence `1.0`, distance influence `5.0`, and deposit constant `10.0`. Invalid input returns `-1e300`.

The source selects cities randomly. The ports use a shared Park–Miller generator seeded with 1 and visit candidate city indices in ascending order to make the benchmark repeatable. With three cities, every closed tour uses the same three edges, so the returned distance is independent of those random choices. The workload still exercises roulette selection, route construction, pheromone evaporation, and pheromone deposits. Results are binary64 with absolute and relative tolerance `1e-12`.

For the fixed three-city shape, runtime is O(ants × iterations) and auxiliary space is O(ants).

| Language | Implementation |
| --- | --- |
| C | [`c/a/ant_colony_optimization.c`](../../../c/a/ant_colony_optimization.c) |
| C3 | [`c3/a/ant_colony_optimization.c3`](../../../c3/a/ant_colony_optimization.c3) |
| C++ | [`cpp/a/ant_colony_optimization.cpp`](../../../cpp/a/ant_colony_optimization.cpp) |
| Elisa | [`elisa/a/ant_colony_optimization.elisa`](../../../elisa/a/ant_colony_optimization.elisa) |
| Nim | [`nim/a/ant_colony_optimization.nim`](../../../nim/a/ant_colony_optimization.nim) |
| Odin | [`odin/a/ant_colony_optimization.odin`](../../../odin/a/ant_colony_optimization.odin) |
| Rust | [`rust/a/ant_colony_optimization.rs`](../../../rust/a/ant_colony_optimization.rs) |
| V | [`v/a/ant_colony_optimization.v`](../../../v/a/ant_colony_optimization.v) |
| Zig | [`zig/a/ant_colony_optimization.zig`](../../../zig/a/ant_colony_optimization.zig) |
