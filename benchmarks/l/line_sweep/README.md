# Line sweep overlap check

The pinned Java `LineSweep.isOverlap` allocates a discrete number line through the maximum range endpoint, adds one at each start and subtracts one just after each end, then scans prefix counts. This treats ranges as inclusive integer intervals and returns whether any point is covered more than once. Its helper sorts ranges by end to find the largest endpoint.

## Contract

Input is `[range_count, start0, end0, ...]`, with 0..8 ranges. Endpoints are integers in `[0,20]` and every range satisfies `start <= end`. Empty input returns false. The scalar result is `1.0` for overlap and `0.0` otherwise; invalid packed input returns `-1e300`.

See [workload](workload.json), [oracle](../../line_sweep_oracle.py), and the pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/LineSweep.java).

| Language | Port |
|---|---|
| C | c/l/line_sweep.c |
| C3 | c3/l/line_sweep.c3 |
| C++ | cpp/l/line_sweep.cpp |
| Elisa | elisa/l/line_sweep.elisa |
| Nim | nim/l/line_sweep.nim |
| Odin | odin/l/line_sweep.odin |
| Rust | rust/l/line_sweep.rs |
| V | v/l/line_sweep.v |
| Zig | zig/l/line_sweep.zig |
