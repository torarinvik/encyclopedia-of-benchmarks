# Lexicographic combinations with repetition

Enumerate fixed-length multisets over a small ordered integer domain. Each multiset is represented as a nondecreasing tuple, so repeated values are allowed and permutations of the same multiset are not emitted separately.

## Contract

The exported `combinations_with_repetition_lexicographic` function uses the `i64_array_bytes_output` ABI with input `[n,r]`, where both values are in `0..4`. Values are drawn from `0..n-1`; a result is a nondecreasing tuple of exactly `r` values. Tuples are emitted in lexicographic ascending order.

The output begins with a little-endian u16 tuple count, followed by `r` bytes for every tuple. Thus the maximum bounded case `[4,4]` has `C(7,4)=35` tuples and uses 142 bytes. For `r=0`, the single empty tuple is emitted, including when `n=0`. When `n=0` and `r>0`, there are no tuples; its output is the zero count header.

Malformed or null input returns `-1`. A null output or capacity smaller than the exact output size returns `-2`, with no output writes. The implementation computes the bounded tuple count and validates capacity before writing the header or tuple data. Caller-owned buffers are excluded from the 128-byte workspace cap.

The primary initializes the all-zero tuple and advances the rightmost coordinate that can increase, then fills its suffix with the increased value. The independent reference recursively chooses each next value from the previous value through `n-1`, directly constructing tuples in lexicographic order. Both produce the same sorted multiset space with different traversal state.

## Sources and duplicate boundary

Knuth's *The Art of Computer Programming*, Volume 4A, §7.2.1.3, treats combinations with repetition among combinatorial generation objects. CP-Algorithms' [combination-generation article](https://cp-algorithms.com/combinatorics/generating_combinations.html) describes the neighboring strictly increasing successor procedure; the nondecreasing repetition rule here is defined by this package contract. The score-18 “Combinations with repetitions” title in the pinned [RosettaCodeData popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) supplied discovery only. No task text, source, examples, or tests are reused.

This benchmark differs from `subset_combinations`, which chooses distinct elements, and `gray_code_k_combinations`, which visits fixed-cardinality subsets in minimal-change order. The nCr profiles return counts without enumerating the multiset tuples.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and [`INVENTORY.md`](INVENTORY.md). The package is registered in the shared `i64_array_bytes_output` suite. Package helpers remain unrun.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/c/combinations_with_repetition_lexicographic.c`](../../../c/c/combinations_with_repetition_lexicographic.c) |
| C3 | [`c3/c/combinations_with_repetition_lexicographic.c3`](../../../c3/c/combinations_with_repetition_lexicographic.c3) |
| C++ | [`cpp/c/combinations_with_repetition_lexicographic.cpp`](../../../cpp/c/combinations_with_repetition_lexicographic.cpp) |
| Elisa | [`elisa/c/combinations_with_repetition_lexicographic.elisa`](../../../elisa/c/combinations_with_repetition_lexicographic.elisa) |
| Mojo | [`mojo/c/combinations_with_repetition_lexicographic.mojo`](../../../mojo/c/combinations_with_repetition_lexicographic.mojo) |
| Nim | [`nim/c/combinations_with_repetition_lexicographic.nim`](../../../nim/c/combinations_with_repetition_lexicographic.nim) |
| Odin | [`odin/c/combinations_with_repetition_lexicographic.odin`](../../../odin/c/combinations_with_repetition_lexicographic.odin) |
| Rust | [`rust/c/combinations_with_repetition_lexicographic.rs`](../../../rust/c/combinations_with_repetition_lexicographic.rs) |
| V | [`v/c/combinations_with_repetition_lexicographic.v`](../../../v/c/combinations_with_repetition_lexicographic.v) |
| Zig | [`zig/c/combinations_with_repetition_lexicographic.zig`](../../../zig/c/combinations_with_repetition_lexicographic.zig) |
