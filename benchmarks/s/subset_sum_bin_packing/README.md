# Subset Sum bin-packing heuristic

Pack items in repeated bins by solving a subset-sum problem for the items not
yet packed. Each bin receives a maximum-total subset whose total does not
exceed the capacity. When multiple subsets attain that total, prefer
including the earliest remaining item at the first differing position. This
deterministic tie rule makes the resulting assignment reproducible.

This is distinct from the local First Fit, Best Fit, and other placement
heuristics: it solves a capacity-bounded subset-sum problem anew for each bin.
The primary reference uses suffix reachability and include-first
reconstruction; the independent reference enumerates subsets exhaustively.

## Contract

Input is `[n,C,size_0,...,size_(n-1)]`, with `1<=n<=16`,
`1<=C<=32`, and every item size in `1..C`. The exact input length is `n+2`;
the maximum valid frame has 18 values and the maximum parseable frame has 19.

The scalar result is `bin_count*10,000 + Σ((i+1)*(assigned_bin_i+1))`, where
items retain their input indices and bin numbers are one-based in the
checksum. Since the assignment checksum is below 10,000, the bin count can
be recovered from the result. Scratch state is bounded to 4,096 bytes.

The greedy repeated subset-sum rule follows Julián Mestre's 2016 [Encyclopedia
of Algorithms entry, pp. 2126–2129](https://link.springer.com/referencework/10.1007/978-1-4939-2864-4?page=29).
An earlier online edition is available at [DOI 10.1007/978-3-642-27848-8_496-1](https://doi.org/10.1007/978-3-642-27848-8_496-1).
Only the algorithm idea was consulted. The bounded contract, tie rule,
workload, references, and ports are independently authored.

| Language | Port |
|---|---|
| C | [c/s/subset_sum_bin_packing.c](../../../c/s/subset_sum_bin_packing.c) |
| C3 | [c3/s/subset_sum_bin_packing.c3](../../../c3/s/subset_sum_bin_packing.c3) |
| C++ | [cpp/s/subset_sum_bin_packing.cpp](../../../cpp/s/subset_sum_bin_packing.cpp) |
| Elisa | [elisa/s/subset_sum_bin_packing.elisa](../../../elisa/s/subset_sum_bin_packing.elisa) |
| Mojo | [mojo/s/subset_sum_bin_packing.mojo](../../../mojo/s/subset_sum_bin_packing.mojo) |
| Nim | [nim/s/subset_sum_bin_packing.nim](../../../nim/s/subset_sum_bin_packing.nim) |
| Odin | [odin/s/subset_sum_bin_packing.odin](../../../odin/s/subset_sum_bin_packing.odin) |
| Rust | [rust/s/subset_sum_bin_packing.rs](../../../rust/s/subset_sum_bin_packing.rs) |
| V | [v/s/subset_sum_bin_packing.v](../../../v/s/subset_sum_bin_packing.v) |
| Zig | [zig/s/subset_sum_bin_packing.zig](../../../zig/s/subset_sum_bin_packing.zig) |
