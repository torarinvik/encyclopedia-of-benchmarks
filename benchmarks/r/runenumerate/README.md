# `runenumerate`: bounded maximal-periodic-run enumeration

This package implements the operation in Library Checker’s [`runenumerate`](https://github.com/yosupo06/library-checker-problems/blob/master/string/runenumerate/task.md) task. It emits every maximal run as `(period, left, right)` with a half-open interval, sorted lexicographically. The task contract is used as a clean-room specification; no upstream implementation or tests are copied.

## Input and output

Input is `[n, c0, ..., c(n-1)]`, where `1 <= n <= 24` and every `ci` is a lowercase-letter code in `0..25`. A run `(t,l,r)` has minimum period `t`, length `r-l >= 2*t`, and cannot be extended one character to either side while keeping period `t`. Indices are zero-based and `r` is exclusive.

Output is a sequence of little-endian signed 64-bit values: the run count followed by each run's `t,l,r` triple in lexicographic order. Malformed input returns `-1`. A null output pointer or capacity shorter than the actual encoded result returns `-2`, without writing. Capacity errors follow full input validation. For the empty run set the output is the eight-byte zero count.

## Bounded algorithm profile

For each candidate period `t`, the ports scan the equality sequence `S[i] == S[i-t]`. A maximal contiguous block of true comparisons identifies the unique maximal interval for that period. They retain intervals of length at least `2*t`, then use a longest-common-prefix table to discard candidates that have a smaller period. The remaining tuples are sorted by `(t,l,r)`.

This exact profile takes `O(n^4)` worst-case time and `O(n^2)` working space at the local `n <= 24` bound: period-block discovery and minimality filtering take `O(n^3)`, followed by bounded insertion sorting of the candidate tuples. It does **not** claim the asymptotic running time of the official contest solution or of linear-time runs algorithms. `MAX_RUNS_BOUND = 144`, so at most 3,464 output bytes are needed. The package uses fixed arrays; its documented algorithm workspace is 9,000 bytes.

`runenumerate_oracle.py` uses period-equality blocks. The independent verifier oracle exhaustively checks intervals, minimality, and both extension conditions.

## Provenance and rights

The upstream problem is part of `yosupo06/library-checker-problems`, whose repository is Apache-2.0 licensed. This package uses only its public operation semantics and attribution; every port and oracle is independently written. See [`workload.json`](workload.json) and [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/runenumerate.c`](../../../c/r/runenumerate.c) |
| C3 | [`c3/r/runenumerate.c3`](../../../c3/r/runenumerate.c3) |
| C++ | [`cpp/r/runenumerate.cpp`](../../../cpp/r/runenumerate.cpp) |
| Elisa | [`elisa/r/runenumerate.elisa`](../../../elisa/r/runenumerate.elisa) |
| Mojo | [`mojo/r/runenumerate.mojo`](../../../mojo/r/runenumerate.mojo) |
| Nim | [`nim/r/runenumerate.nim`](../../../nim/r/runenumerate.nim) |
| Odin | [`odin/r/runenumerate.odin`](../../../odin/r/runenumerate.odin) |
| Rust | [`rust/r/runenumerate.rs`](../../../rust/r/runenumerate.rs) |
| V | [`v/r/runenumerate.v`](../../../v/r/runenumerate.v) |
| Zig | [`zig/r/runenumerate.zig`](../../../zig/r/runenumerate.zig) |
