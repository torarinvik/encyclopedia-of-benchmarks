# Farey sequence ordered enumeration

This package emits the complete Farey sequence of a supplied order using the
constant-space adjacent-fraction successor recurrence. It is distinct from
[`farey_approximation`](../farey_approximation/README.md), which repeatedly
refines one target decimal and returns only its final mediant, and from
[`stern_brocot_tree`](../stern_brocot_tree/README.md), which serves path and
navigation queries rather than enumerating the order-bounded sequence.

## Contract

Input is the one-word signed-i64 array `[N]`, with `1<=N<=32`. The output is
`[count,p_0,q_0,...,p_(count-1),q_(count-1)]`, encoded as little-endian signed
64-bit words. It contains each reduced fraction in `[0,1]` whose denominator
is at most `N`, in strictly increasing rational order. Both endpoints appear
exactly once, as `0/1` and `1/1`.

The output begins with `a/b=0/1`. The successor state starts from the adjacent
terms `a/b=0/1` and `c/d=1/N`; emit `c/d`, and if it is `1/1`, stop. Otherwise calculate
`k=floor((N+b)/d)`, then advance to `(k*c-a)/(k*d-b)`, retaining the old
`c/d` as the new left term. All terms are reduced by construction. The ports
make a first successor pass to count terms and check the exact output capacity
before writing; a second pass serializes the count and all fraction pairs.
The measured kernel includes both passes and serialization.

For `N<=32`, each recurrence product is bounded by `k*d<=N+b<=64`; all
state and output words therefore fit signed i64. Farey sequences are nested
as the order increases, and OEIS [A005728](https://oeis.org/A005728) gives
`|F_32|=325`. Therefore the maximum serialized frame is exactly 651 words
or 5,208 bytes. The algorithm uses scalar state only, for a declared native
workspace of zero bytes (caller-owned input and output excluded). Runtime is
`O(|F_N|)` for each pass and auxiliary space is `O(1)`.

Malformed input returns `-1`. A null or undersized output buffer returns
`-2`; no output bytes are written on either error. The valid input length is
one word and the parseable length is two words, allowing a trailing-word
fixture.

## References and provenance

RosettaGit's [Farey sequence task](https://rosettagit.org/tasks/farey-sequence/)
and the pinned [RosettaCodeData popular-title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
identify the task and its required endpoint and ordering semantics. The
successor relation is cross-checked with [MathWorld's Farey Sequence entry](https://mathworld.wolfram.com/FareySequence.html)
and the ordered-generation discussion in Pătrașcu and Pătrașcu,
[“Computing Order Statistics in the Farey Sequence”](https://people.csail.mit.edu/mip/papers/farey/farey.pdf).
The independent reference enumerates reduced `p/q` candidates with gcd and
sorts by exact cross-products; it does not use the successor state.

All source and workload data in this package were written independently.
RosettaGit and RosettaCodeData are discovery and high-level specification
references only. No task code, prose, sample output list, or test material was
copied. [`RIGHTS.md`](RIGHTS.md) records these boundaries.

## Workload and static inventory

[`workload.json`](workload.json) contains new order-12 and order-32 fixtures,
plus invalid-input and output-error cases. Valid payloads are derived from the
two references by the package-local [`verify_workload.py`](verify_workload.py);
the term counts are pinned to OEIS [A005728](https://oeis.org/A005728). The
static file manifest is [`INVENTORY.json`](INVENTORY.json), and
[`check_inventory.py`](check_inventory.py) checks package paths and declared
bounds without executing a benchmark.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/farey_sequence_ordered_enumeration.c`](../../../c/f/farey_sequence_ordered_enumeration.c) |
| C3 | [`c3/f/farey_sequence_ordered_enumeration.c3`](../../../c3/f/farey_sequence_ordered_enumeration.c3) |
| C++ | [`cpp/f/farey_sequence_ordered_enumeration.cpp`](../../../cpp/f/farey_sequence_ordered_enumeration.cpp) |
| Elisa | [`elisa/f/farey_sequence_ordered_enumeration.elisa`](../../../elisa/f/farey_sequence_ordered_enumeration.elisa) |
| Mojo | [`mojo/f/farey_sequence_ordered_enumeration.mojo`](../../../mojo/f/farey_sequence_ordered_enumeration.mojo) |
| Nim | [`nim/f/farey_sequence_ordered_enumeration.nim`](../../../nim/f/farey_sequence_ordered_enumeration.nim) |
| Odin | [`odin/f/farey_sequence_ordered_enumeration.odin`](../../../odin/f/farey_sequence_ordered_enumeration.odin) |
| Rust | [`rust/f/farey_sequence_ordered_enumeration.rs`](../../../rust/f/farey_sequence_ordered_enumeration.rs) |
| V | [`v/f/farey_sequence_ordered_enumeration.v`](../../../v/f/farey_sequence_ordered_enumeration.v) |
| Zig | [`zig/f/farey_sequence_ordered_enumeration.zig`](../../../zig/f/farey_sequence_ordered_enumeration.zig) |
