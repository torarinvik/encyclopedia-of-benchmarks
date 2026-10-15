# Van Eck's sequence

## Contract

The input is a one-based position from 1 through 16. Return the corresponding Van Eck sequence term, beginning `0, 0, 1, 0, 2, 0, 2, 2, 1, 6, 0, 5, 0, 2, 6, 5`. Return `-1` outside the supported range.

The scalar ABI is `int64_t van_ecks_sequence(int64_t position)`. The fixed bound keeps the source's unbounded generator practical for a scalar benchmark; all terms in this prefix fit signed 64-bit integers. Implementations preserve the pinned source's last-occurrence recurrence: for each position, emit zero if the preceding value has not appeared, otherwise emit the distance from its previous position, then record the preceding value at the current position.

## Source behavior and related sequences

The pinned C# iterator yields the initial zero and uses a dictionary from a sequence value to its most recent one-based position. The local contract indexes those yielded terms one-based and applies the same update order. A zero last-seen position is used locally as the unseen sentinel, since generated positions begin at one.

This is distinct from Recamán's sequence, which subtracts the current index when the result is positive and unused, and otherwise adds the index. Both are integer sequences, but they have different recurrences and terms.

## Workload

[`workload.json`](workload.json) covers the initial terms, repeated-value gaps, the last supported position, and invalid positions on both sides of the domain.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/v/van_ecks_sequence.c`](../../../c/v/van_ecks_sequence.c) |
| C3 | [`c3/v/van_ecks_sequence.c3`](../../../c3/v/van_ecks_sequence.c3) |
| C++ | [`cpp/v/van_ecks_sequence.cpp`](../../../cpp/v/van_ecks_sequence.cpp) |
| Elisa | [`elisa/v/van_ecks_sequence.elisa`](../../../elisa/v/van_ecks_sequence.elisa) |
| Nim | [`nim/v/van_ecks_sequence.nim`](../../../nim/v/van_ecks_sequence.nim) |
| Odin | [`odin/v/van_ecks_sequence.odin`](../../../odin/v/van_ecks_sequence.odin) |
| Rust | [`rust/v/van_ecks_sequence.rs`](../../../rust/v/van_ecks_sequence.rs) |
| V | [`v/v/van_ecks_sequence.v`](../../../v/v/van_ecks_sequence.v) |
| Zig | [`zig/v/van_ecks_sequence.zig`](../../../zig/v/van_ecks_sequence.zig) |

## TheAlgorithms reference

- [C# `VanEcksSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/VanEcksSequence.cs)
