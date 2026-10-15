# Recamán's sequence

## Contract

The input is a zero-based index `n` from 0 through 32. Return term `a(n)` of Recamán's sequence, beginning `0, 1, 3, 6, 2, 7, 13, 20, 12, 21, 11, ...`. For each step `i` starting at one, subtract `i` from the previous term when the result is nonnegative and has not appeared earlier; otherwise add `i`. Return `-1` outside the supported index range.

The scalar ABI is `int64_t recamans_sequence(int64_t index)`. The bound keeps all terms within a small finite visited-value table: at step `i`, no term can exceed the sum `1 + ... + i`, so a table with indices 0 through 528 covers every intermediate value through index 32. The ports preserve the source's visited-set check and update order.

## Source behavior and related sequences

The pinned C# generator yields `a(0)=0`, initializes its set with zero, and then applies the subtract-if-nonnegative-and-unseen rule for `i=1,2,...`. The local contract is zero-based and returns one generated term per call. A fixed boolean table has the same membership behavior as the source `HashSet<BigInteger>` over this bounded domain.

This differs from Van Eck's sequence: Recamán's sequence chooses between subtracting and adding the current index based on whether the proposed value was seen, while Van Eck uses the distance to the previous occurrence of the preceding term. Their terms already differ at index 2 (`3` versus `1`).

## Workload

[`workload.json`](workload.json) covers the initial terms, both recurrence branches, a later term, the largest supported index, and invalid indices.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/recamans_sequence.c`](../../../c/r/recamans_sequence.c) |
| C3 | [`c3/r/recamans_sequence.c3`](../../../c3/r/recamans_sequence.c3) |
| C++ | [`cpp/r/recamans_sequence.cpp`](../../../cpp/r/recamans_sequence.cpp) |
| Elisa | [`elisa/r/recamans_sequence.elisa`](../../../elisa/r/recamans_sequence.elisa) |
| Nim | [`nim/r/recamans_sequence.nim`](../../../nim/r/recamans_sequence.nim) |
| Odin | [`odin/r/recamans_sequence.odin`](../../../odin/r/recamans_sequence.odin) |
| Rust | [`rust/r/recamans_sequence.rs`](../../../rust/r/recamans_sequence.rs) |
| V | [`v/r/recamans_sequence.v`](../../../v/r/recamans_sequence.v) |
| Zig | [`zig/r/recamans_sequence.zig`](../../../zig/r/recamans_sequence.zig) |

## TheAlgorithms reference

- [C# `RecamansSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/RecamansSequence.cs)
