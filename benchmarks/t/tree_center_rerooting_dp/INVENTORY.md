# Implementation inventory

Algorithm: `tree_center_rerooting_dp`  
ABI: `i64_array_bytes_output`  
Symbol: `tree_center_rerooting_dp`

The primary uses two-pass tree rerooting; the independent oracle uses
all-sources BFS. All ten supported language ports are listed in README.md.
Source idea: https://oi-wiki.org/graph/tree-center/. Code, prose, examples,
and fixtures were not copied. Implementation status and suite registration are
tracked in `benchmarks/ALGORITHM_EXPANSION_COVERAGE.md`.
