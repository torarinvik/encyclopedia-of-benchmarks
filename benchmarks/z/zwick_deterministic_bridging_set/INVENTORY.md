# Package inventory

Algorithm: `zwick_deterministic_bridging_set`  
ABI: `i64_array_scalar`  
Workspace bound: 4,096 bytes

The bounded frame contains a loop-free strongly connected directed graph and
a validated shortest-path witness matrix, both with at most eight vertices.
The output is the greedy bridge-set bit mask.

Package artifacts: README, rights/provenance, workload, primary and
independent references, workload reconciler, inventory JSON, and static
inventory checker. The ten native source paths are listed in `INVENTORY.json`.

All contents are clean-room descriptions of algorithm ideas. Static source
review only; no programs, tests, helpers, checkers, builds, compilers, or
benchmarks were run.
