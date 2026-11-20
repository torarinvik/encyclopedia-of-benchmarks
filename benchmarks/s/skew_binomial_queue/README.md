# Skew binomial queue

This profile implements the non-bootstrapped skew binomial queue of Brodal and
Okasaki. Its forest keeps roots in increasing rank order, with an equal-rank
pair allowed only at the two smallest ranks. Insertion checks that pair and,
when needed, combines it with the new singleton using a three-tree skew link.
Delete-min separates rank-zero singleton children from positive-rank children,
melds the latter with the remaining forest, then reinserts the singletons.

This differs from the ordinary binomial heap, which handles insertion through
repeated binary carries, and from the self-adjusting skew heap, which is one
tree maintained by recursive melding. The selected primitive queue exposes
insert, find-min, and delete-min. It does not use the paper's later global-root
or bootstrapping transformations.

## Contract

The `i64_array_scalar` input is `[m, (opcode, item_id, key)*m]`, with
`0 <= m <= 64`, exact length `1 + 3*m`, maximum valid length 193, and maximum
parseable length 194. Item IDs are in `0..31`; keys are in `0..1_000_000`.

- Opcode `1` inserts an item ID that is not currently active, with the given
  key. An ID can be reused after its item is deleted.
- Opcode `2` finds the minimum and requires both operands to be 0.
- Opcode `3` deletes the minimum and requires both operands to be 0.
- Roots use the total order `(key, insertion_serial, item_id, node_creation_index)`.
  The serial is unique per insertion; the remaining fields pin deterministic
  tie handling in every port.
- Each find-min or delete-min adds
  `(one_based_operation_index * (key + 1)) + item_id` to the result.
- Invalid, null, or incorrectly sized input returns `-1`; a valid trace with
  no query or deletion returns `0`.

The bounded ports use arrays and may take O(m^2) time and O(m) space. The
underlying forest uses O(1) worst-case insertion and O(log n) find-min and
delete-min. Insertions use type-A or type-B skew links according to the
three roots' pinned key order. During delete-min, the remaining forest and
positive-rank children are normalized by equal-rank simple links; detached
rank-zero children are reinserted in insertion-serial order. This pins a
deterministic meld and singleton-reinsertion order for the benchmark.
Both skew-link forms produce rank `r+1`; in type A this must be assigned to
the new singleton root rather than computed by incrementing its old rank zero.

Two references and workload cases cover both skew-link branches, equal-key
stability, rank-zero reinsertion, positive-rank children, item-ID reuse,
malformed traces, and the maximum frame. Implementations are independently
written from the published algorithm description; checks have not been run.

| Language | Port |
|---|---|
| C | [c/s/skew_binomial_queue.c](../../../c/s/skew_binomial_queue.c) |
| C3 | [c3/s/skew_binomial_queue.c3](../../../c3/s/skew_binomial_queue.c3) |
| C++ | [cpp/s/skew_binomial_queue.cpp](../../../cpp/s/skew_binomial_queue.cpp) |
| Elisa | [elisa/s/skew_binomial_queue.elisa](../../../elisa/s/skew_binomial_queue.elisa) |
| Mojo | [mojo/s/skew_binomial_queue.mojo](../../../mojo/s/skew_binomial_queue.mojo) |
| Nim | [nim/s/skew_binomial_queue.nim](../../../nim/s/skew_binomial_queue.nim) |
| Odin | [odin/s/skew_binomial_queue.odin](../../../odin/s/skew_binomial_queue.odin) |
| Rust | [rust/s/skew_binomial_queue.rs](../../../rust/s/skew_binomial_queue.rs) |
| V | [v/s/skew_binomial_queue.v](../../../v/s/skew_binomial_queue.v) |
| Zig | [zig/s/skew_binomial_queue.zig](../../../zig/s/skew_binomial_queue.zig) |

The algorithm follows Brodal and Okasaki's [Optimal Purely Functional Priority
Queues](https://doi.org/10.1017/S095679680000201X), Section 3. Only algorithmic
ideas are used; source code and prose are independently written.
