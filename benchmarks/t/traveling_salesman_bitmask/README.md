# Traveling salesman bitmask dynamic programming

Compute the least cost of a closed tour that starts at city 0, visits every city exactly once, and returns to city 0. This package ports the `tsp_bitmask_dp` function from the pinned R source.

## Contract

Input is `[n, d00, d01, ..., d(n-1)(n-1)]`, with the distance matrix flattened in row-major order. The matrix is directed, has 2–10 cities, has a zero diagonal, and each distance is an integer in `[0, 1000]`. Input length must be exactly `1 + n*n`; the parser accepts up to 102 values so it can reject a trailing value after the largest valid input.

The result is the minimum closed-tour cost, in `[0, 10,000]`. Invalid input returns `-1`. The pinned recurrence starts at city 0 with only bit 0 set, recursively visits every city whose bit is clear in ascending city order, and adds the edge back to city 0 after all cities have been visited. The source's separate path-reconstruction function is outside this scalar contract.

The source uses signed 32-bit bit operations, so the benchmark caps the graph at 10 cities. The bound also keeps the state table small and all tour costs within signed 64-bit range.

Pinned source: [`travelingSalesman_bitmask.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/dynamic_programming/travelingSalesman_bitmask.r), function `tsp_bitmask_dp`.

See [workload](workload.json) and [oracle](../../traveling_salesman_bitmask_oracle.py).

| Language | Port |
|---|---|
| C | [traveling_salesman_bitmask.c](../../../c/t/traveling_salesman_bitmask.c) |
| C3 | [traveling_salesman_bitmask.c3](../../../c3/t/traveling_salesman_bitmask.c3) |
| C++ | [traveling_salesman_bitmask.cpp](../../../cpp/t/traveling_salesman_bitmask.cpp) |
| Elisa | [traveling_salesman_bitmask.elisa](../../../elisa/t/traveling_salesman_bitmask.elisa) |
| Nim | [traveling_salesman_bitmask.nim](../../../nim/t/traveling_salesman_bitmask.nim) |
| Odin | [traveling_salesman_bitmask.odin](../../../odin/t/traveling_salesman_bitmask.odin) |
| Rust | [traveling_salesman_bitmask.rs](../../../rust/t/traveling_salesman_bitmask.rs) |
| V | [traveling_salesman_bitmask.v](../../../v/t/traveling_salesman_bitmask.v) |
| Zig | [traveling_salesman_bitmask.zig](../../../zig/t/traveling_salesman_bitmask.zig) |
