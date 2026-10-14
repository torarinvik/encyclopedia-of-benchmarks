# Encyclopedia of Benchmarks

A cross-platform collection for comparing algorithm implementations across programming languages. TheAlgorithms repositories are the initial discovery source. When an algorithm has no implementation in one of our target languages, we will write one and record it as a port.

## Goals

- Catalog algorithms and implementations across languages.
- Compare implementations only when they solve the same problem with the same input and output semantics.
- Keep a portable baseline for every benchmark. Default code must not depend on Intel-only instructions or x86-only compiler flags.
- Record enough source, build, machine, and workload details to reproduce a result.
- Preserve attribution and license information for any code taken from an upstream project.

## Layout

The current language folders are `c`, `c3`, `cpp`, `elisa`, `nim`, `odin`, `rust`, `v`, and `zig`. Algorithms are grouped by the first letter of the algorithm name, for example `rust/l/linear_search.rs`; names beginning with a digit go under `0-9/`. Workloads and result files use the same organization, such as `benchmarks/l/linear_search/` and `results/l/linear_search/`.

The first source-path inventory is in [CATALOG.md](CATALOG.md) and [`catalog/algorithm-candidates.json`](catalog/algorithm-candidates.json). The reviewed benchmarks currently include `linear_search`, `binary_search`, and `exponential_search`, with shared contracts, workloads, and portable implementations. The shared C ABI search runner records them. See the [linear search guide](benchmarks/l/linear_search/README.md), [binary search guide](benchmarks/b/binary_search/README.md), [exponential search guide](benchmarks/e/exponential_search/README.md), and [benchmarking instructions](BENCHMARKING.md).
