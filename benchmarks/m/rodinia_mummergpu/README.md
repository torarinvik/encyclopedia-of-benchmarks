# Rodinia MUMmerGPU bounded maximal exact matches

This package implements MUMmerGPU's all-maxmatch query semantics for one short reference and one short query. It indexes reference suffixes in a bounded uncompressed suffix trie, then traverses that index while matching each query suffix. The Python oracle instead enumerates every reference/query start pair directly.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol: `rodinia_mummergpu`.
- Input: `[reference_length, query_length, min_match_length, reference_codes..., query_codes...]`. The codes are `A=0`, `C=1`, `G=2`, `T=3`. Both sequences have lengths 1–32; the minimum match length is 1–32 and is inclusive. A threshold longer than a sequence is valid and returns no matches.
- The index has child order `A,C,G,T,$`. Each query start is considered in ascending order. A pair is reported if its longest common prefix is at least the threshold, its preceding symbols differ (or one start is at sequence position 1), and its following symbols differ (or one match reaches a sequence end).
- Output records use the source text format's coordinate order: reference start, query start, match length. Starts are 1-based. Records are emitted by increasing query start, then in reference suffix-tree DFS order, equivalent to `A,C,G,T,$` lexicographic ordering of terminated reference suffixes. Repeated matches at distinct coordinate pairs are retained.
- Each record is three signed 64-bit little-endian values. Return the byte count (`24 * match_count`); return 0 for a valid query with no qualifying matches. Invalid input returns `-1`; null or short output returns `-2` without writes.
- Bounds cap each string at 32 bases (at most 1,024 candidate coordinate pairs) and output at 24,576 bytes. Only uppercase DNA bases are represented. FASTA parsing, multiple-query files, reverse-complement matching, and output headers are outside this contract.

The source CLI defaults to minimum match length 20 and forces the all-maxmatch mode. The workload includes a length-20 fixture at the source default, along with repeated-base ties, left-maximal filtering, no-match, and error cases.

## Source and rights

- Pinned source: [`cuda/mummergpu`](https://github.com/utcs-scea/rodinia/tree/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/mummergpu), Rodinia commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`.
- The subtree's source license is in [`LICENSE.txt`](LICENSE.txt), copied from its `COPYING` file. MUMmerGPU is attributed to Michael Schatz, Cole Trapnell, Art Delcher, and Amitabh Varshney.
- These ports are clean-room implementations of the bounded matching contract, not translations of the CUDA kernels or suffix-tree source text. The package removes CUDA storage/layout, FASTA and file I/O, multi-query execution, reverse complements, paging, and timers.
- The source `README` describes arbitrary non-DNA handling; this deterministic profile rejects symbols outside A/C/G/T rather than reproducing its ambiguous-base conversions.

## Files

- Nine ports are in `c/m`, `c3/m`, `cpp/m`, `elisa/m`, `nim/m`, `odin/m`, `rust/m`, `v/m`, and `zig/m`.
- Independent oracle: [`benchmarks/rodinia_mummergpu_oracle.py`](../../rodinia_mummergpu_oracle.py).
- Workload and fixtures: [`workload.json`](workload.json).
