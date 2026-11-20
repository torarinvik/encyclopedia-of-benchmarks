# Package inventory

Algorithm: `bk_tree_edit_distance_search`  
ABI: `i64_array_scalar`  
Status: complete; shared suite and catalog integration are registered.

The package includes the bounded contract, workload, rights/provenance note,
primary BK-tree reference, independent full-scan/full-matrix reference,
workload validator, static inventory checker, and ten native ports. The
contract bounds the valid and parseable frames to 27 and 28 i64 values,
respectively, caps fixed workspace at 4,096 bytes, and returns a scalar
checksum no greater than 14,112.

No executable validation was performed. No programs, tests, scripts, helpers,
checkers, builds, compilers, profilers, or benchmarks were run.
