# Number of Increasing Sequences Between Two Sequences

This package adapts the [Library Checker problem](https://judge.yosupo.jp/problem/number_of_increasing_sequences_between_two_sequences) to a bounded scalar call. Given per-position half-open integer intervals `[A_i, B_i)`, it counts the integer vectors `x` satisfying `A_i <= x_i < B_i` and `x_0 <= x_1 <= ... <= x_(n-1)`, modulo 998244353.

## Contract

The scalar ABI is `int64_t number_of_increasing_sequences_between_two_sequences(const int64_t *input, size_t length)`. Input is packed as `[n, m, A_0, ..., A_(n-1), B_0, ..., B_(n-1)]`. The local bounds are `1 <= n,m <= 64`, with `0 <= A_i < B_i <= m`; values of `x` are therefore in `[0,m)`. The exact input length is `2 + 2*n`. Null, malformed, or out-of-range input returns `-1`.

For the first position, each value in its allowed interval has one way to be chosen. At each later position `i`, the number of sequences ending at value `v` is the prefix sum of the previous row through `v`, when `A_i <= v < B_i`. The primary implementation runs in `O(n*m)` time and `O(m)` space. The independent oracle uses memoized recursion over `(position, previous value)` and enumerates allowed next values, taking `O(n*m^2)` time at the local bounds.

The official task permits `n,m <= 2^17`; this profile caps both at 64 to keep the packed scalar contract and all ten ports bounded. It counts assignments from position-specific integer intervals under a weak nondecreasing constraint. It is distinct from [`longest_increasing_subsequence`](../../l/longest_increasing_subsequence/README.md), which optimizes the length of a subsequence of one fixed input; from [`non_empty_subsequences`](../non_empty_subsequences/README.md), which enumerates positional subsequences of a fixed string; and from [`unique_subsequences_count`](../../u/unique_subsequences_count/README.md), which counts distinct nonempty string subsequences.

## Workload and oracles

[`workload.json`](workload.json) includes the two official samples that fit the local bound, small intervals with hand-checkable counts, a maximum-size forced sequence, impossible monotonic bounds, and malformed inputs. [`primary_oracle.py`](primary_oracle.py) implements the prefix-sum recurrence. [`independent_oracle.py`](independent_oracle.py) uses memoized DFS rather than the DP recurrence.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/n/number_of_increasing_sequences_between_two_sequences.c`](../../../c/n/number_of_increasing_sequences_between_two_sequences.c) |
| C3 | [`c3/n/number_of_increasing_sequences_between_two_sequences.c3`](../../../c3/n/number_of_increasing_sequences_between_two_sequences.c3) |
| C++ | [`cpp/n/number_of_increasing_sequences_between_two_sequences.cpp`](../../../cpp/n/number_of_increasing_sequences_between_two_sequences.cpp) |
| Elisa | [`elisa/n/number_of_increasing_sequences_between_two_sequences.elisa`](../../../elisa/n/number_of_increasing_sequences_between_two_sequences.elisa) |
| Mojo | [`mojo/n/number_of_increasing_sequences_between_two_sequences.mojo`](../../../mojo/n/number_of_increasing_sequences_between_two_sequences.mojo) |
| Nim | [`nim/n/number_of_increasing_sequences_between_two_sequences.nim`](../../../nim/n/number_of_increasing_sequences_between_two_sequences.nim) |
| Odin | [`odin/n/number_of_increasing_sequences_between_two_sequences.odin`](../../../odin/n/number_of_increasing_sequences_between_two_sequences.odin) |
| Rust | [`rust/n/number_of_increasing_sequences_between_two_sequences.rs`](../../../rust/n/number_of_increasing_sequences_between_two_sequences.rs) |
| V | [`v/n/number_of_increasing_sequences_between_two_sequences.v`](../../../v/n/number_of_increasing_sequences_between_two_sequences.v) |
| Zig | [`zig/n/number_of_increasing_sequences_between_two_sequences.zig`](../../../zig/n/number_of_increasing_sequences_between_two_sequences.zig) |

## Source

Problem statement and sample cases: [Library Checker, Number of Increasing Sequences Between Two Sequences](https://judge.yosupo.jp/problem/number_of_increasing_sequences_between_two_sequences). The upstream problem collection is maintained in [yosupo06/library-checker-problems](https://github.com/yosupo06/library-checker-problems). These bounded implementations are clean-room code; no upstream solution source is copied.
