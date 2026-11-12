# Stern–Brocot Tree Queries

This benchmark implements the five number-theory operations in Library Checker’s Stern–Brocot Tree task: run-length path encoding, path decoding, lowest common ancestor, fixed-depth ancestor, and the open rational interval containing a node’s descendants. A positive reduced fraction identifies one node; a left or right move updates one of two neighboring Farey bounds by a mediant. The local implementation batches these operations in one call and stores results as tagged signed 64-bit words.

## Contract

Input is a signed 64-bit array beginning with a query count `T` in `1..=128`. Each query begins with an operation code: `0` encodes the path to `[a,b]`; `1` decodes `[run_count,(direction,count)...]`; `2` finds the LCA of `[a,b]` and `[c,d]`; `3` asks for the ancestor at depth `k` of `[a,b]`; `4` returns the descendant interval for `[a,b]`. Directions are `0=L`, `1=R`. Query records are concatenated without separators. Fractions are reduced positive pairs with numerator and denominator at most 1,000,000,000. Run counts and ancestor depths are at most 1,000,000,000; direction runs must alternate. The total input is at most 16,384 words and each path has at most 64 runs.

Output consists of tagged signed-i64 words in little-endian byte order. Each result starts with its operation code. Encoded paths then contain a run count and `(direction,count)` pairs; decoded paths and LCAs contain a numerator and denominator; missing ancestors contain only `-1`; descendant ranges contain lower numerator/denominator and upper numerator/denominator. The return value is the number of queries. Invalid input returns `-1`; insufficient output capacity or a null output pointer returns `-2`. Maximum output is 262,144 bytes. Path encoding and common-prefix/LCA work in `O(log max(a,b))`; path decoding and range/ancestor operations work in `O(r)` for `r` encoded runs. The batch uses `O(T + r)` workspace.

This workload normalizes Library Checker’s textual operation names into integer tags and caps the problem size for a portable, single-call ABI. It does not reuse task statements, tests, or submissions. The [official task contract](https://judge.yosupo.jp/problem/stern_brocot_tree) and [upstream task description](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/stern_brocot_tree/task.md) define the five operations and fraction conventions. The local oracle is [`benchmarks/stern_brocot_tree_oracle.py`](../../stern_brocot_tree_oracle.py).

See [`workload.json`](workload.json) for one fixture for each query operation.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/stern_brocot_tree.c`](../../../c/s/stern_brocot_tree.c) |
| C3 | [`c3/s/stern_brocot_tree.c3`](../../../c3/s/stern_brocot_tree.c3) |
| C++ | [`cpp/s/stern_brocot_tree.cpp`](../../../cpp/s/stern_brocot_tree.cpp) |
| Elisa | [`elisa/s/stern_brocot_tree.elisa`](../../../elisa/s/stern_brocot_tree.elisa) |
| Nim | [`nim/s/stern_brocot_tree.nim`](../../../nim/s/stern_brocot_tree.nim) |
| Odin | [`odin/s/stern_brocot_tree.odin`](../../../odin/s/stern_brocot_tree.odin) |
| Rust | [`rust/s/stern_brocot_tree.rs`](../../../rust/s/stern_brocot_tree.rs) |
| V | [`v/s/stern_brocot_tree.v`](../../../v/s/stern_brocot_tree.v) |
| Zig | [`zig/s/stern_brocot_tree.zig`](../../../zig/s/stern_brocot_tree.zig) |
