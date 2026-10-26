# LPT for maximizing minimum machine load

This bounded profile implements the identical-machine LPT rule described in
“Maximizing the Minimum Machine Load” (Encyclopedia of Algorithms, DOI
[`10.1007/978-1-4939-2864-4_503`](https://doi.org/10.1007/978-1-4939-2864-4_503)):
sort jobs by nonincreasing processing time, then assign each job to a machine
with the least current load. Ties use the lower job ID and lower machine ID.

Input is `[n,m,p_0,...,p_(n-1)]`, with `1<=n<=16`, `1<=m<=4`, and each
processing time in `[1,100]`. Output is `[minimum_final_load, assignments by
job ID, final loads by machine ID]`, encoded as little-endian signed i64s.
This is the source's greedy approximation rule on identical machines; the
reported objective is the least final load produced by this schedule.

The ports are clean-room implementations.

| Language | Port |
|---|---|
| C | `c/m/max_minimum_machine_load_lpt.c` |
| C3 | `c3/m/max_minimum_machine_load_lpt.c3` |
| C++ | `cpp/m/max_minimum_machine_load_lpt.cpp` |
| Elisa | `elisa/m/max_minimum_machine_load_lpt.elisa` |
| Nim | `nim/m/max_minimum_machine_load_lpt.nim` |
| Odin | `odin/m/max_minimum_machine_load_lpt.odin` |
| Rust | `rust/m/max_minimum_machine_load_lpt.rs` |
| V | `v/m/max_minimum_machine_load_lpt.v` |
| Zig | `zig/m/max_minimum_machine_load_lpt.zig` |
