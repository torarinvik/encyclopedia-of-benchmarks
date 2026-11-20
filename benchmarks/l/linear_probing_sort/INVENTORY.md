# Package inventory

- `workload.json` defines the bounded byte-key `sort_call` profile and semantic fixtures.
- `primary_oracle.py` independently models interpolation, linear probing, and compaction.
- `independent_oracle.py` uses Python's built-in ordering operation.
- `verify_workload.py` statically checks package metadata, fixture results, documentation links, and all ten source paths.
- `benchmarks/verify_linear_probing_sort.py` provides the repository sort-checker and workload-recorder workflow, including a 1,024-key maximum-home overflow case; it has not been run.
- Implementations are in C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.

The source is the NIST [linear probing sort](https://xlinux.nist.gov/dads/HTML/linearProbingSort.html) definition. Only the algorithm description was used.
