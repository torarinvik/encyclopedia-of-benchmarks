# Dynamic Predecessor Problem

Maintain a dynamic set over a bounded integer universe with insert, delete, membership, successor, and predecessor operations. The [official Library Checker statement](https://judge.yosupo.jp/problem/predecessor_problem) defines the operation semantics and a bit-string initial state. This package uses the statement only as an algorithm and workload reference and writes independent implementations.

## Contract

Input is a signed 64-bit vector `[N, Q, packed_word..., (operation, key)...]`. `N` is 1 through 4,096 and `Q` is 0 through 512. The initial set is packed into `ceil(N/64)` words; bit `k % 64` of word `k / 64` represents key `k`, with unused high bits in the final word required to be zero. An input word's signed i64 value is interpreted as its two's-complement u64 bit pattern. Every key is in `[0,N)`.

Operations are `0 k` insert, `1 k` delete, `2 k` membership, `3 k` successor (smallest present key at least `k`), and `4 k` predecessor (largest present key at most `k`). Insert and delete are idempotent. Each query operation emits one signed i64 result; membership emits 0 or 1 and missing neighbors emit -1. Results are little-endian signed i64 words. Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writing. The maximum result is 512 words (4,096 bytes).

The implementation stores membership in packed 64-bit words. Membership and updates take `O(1)` time; successor and predecessor scan words in the requested direction and inspect at most one nonzero word, for `O(N/64 + 64)` worst-case search time. Storage is `O(N/64)`. See [`workload.json`](workload.json) and the independent [set-based oracle](../../predecessor_problem_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/predecessor_problem.c`](../../../c/p/predecessor_problem.c) |
| C3 | [`c3/p/predecessor_problem.c3`](../../../c3/p/predecessor_problem.c3) |
| C++ | [`cpp/p/predecessor_problem.cpp`](../../../cpp/p/predecessor_problem.cpp) |
| Elisa | [`elisa/p/predecessor_problem.elisa`](../../../elisa/p/predecessor_problem.elisa) |
| Mojo | [`mojo/p/predecessor_problem.mojo`](../../../mojo/p/predecessor_problem.mojo) |
| Nim | [`nim/p/predecessor_problem.nim`](../../../nim/p/predecessor_problem.nim) |
| Odin | [`odin/p/predecessor_problem.odin`](../../../odin/p/predecessor_problem.odin) |
| Rust | [`rust/p/predecessor_problem.rs`](../../../rust/p/predecessor_problem.rs) |
| V | [`v/p/predecessor_problem.v`](../../../v/p/predecessor_problem.v) |
| Zig | [`zig/p/predecessor_problem.zig`](../../../zig/p/predecessor_problem.zig) |
