# Pagoda meldable priority queue

This profile implements the pagoda priority queue from Francon, Viennot, and
Vuillemin. Each node has two links: `g` is the parent link for a left child
and the leftmost descendant link for a right child; `d` is the parent link
for a right child and the rightmost descendant link for a left child. A
missing opposite descendant is `NIL`. A root stores the bottom leaf of each
extreme branch, using the root itself when that branch has no child. A meld takes the right
branch of its first queue and the left branch of its second, and merges those
increasing key paths from their largest leaves upward. A node from the first
queue makes the accumulated chain its right child; a node from the second
queue makes it the left child. The untouched opposite subtree remains in
place.

## Trace contract

The `i64_array_scalar` input is
`[queue_count, operation_count, (opcode, first, second, priority)*]`.
There are 1–8 queue handles and 0–64 operations. A record has four i64 words:

| Opcode | Record | Effect |
|---|---|---|
| 1 | `(1, queue, 0, priority)` | Insert a singleton by melding `queue` with it. |
| 2 | `(2, destination, source, 0)` | Meld source into destination, then empty source. |
| 3 | `(3, queue, 0, 0)` | Return the current minimum without removing it. |
| 4 | `(4, queue, 0, 0)` | Extract the minimum. |

All handles must be in range. Melding a queue with itself, querying an empty
queue, unknown opcodes, or nonzero unused fields invalidate the whole trace.
Melding empty queues is valid. Inserted priorities are in `[-1000,1000]` and
must be globally unique over the entire trace, even after extraction. This
matches the paper's explicit simplifying assumption of distinct priorities
and leaves every comparison deterministic.

Each MIN or EXTRACTMIN adds
`(one_based_operation_index * (priority + 1001))` to the scalar result. This
keeps every term positive and distinguishes query order. The largest possible
result is `2001 * (2+...+64) = 4,160,079`: operation 1 inserts the maximum
priority and each remaining operation queries it. Malformed input returns
`-1`.
The maximum valid frame has 258 words; 259 words is the parser limit, so an
extra trailing word is rejected safely. The workspace cap is 4096 bytes,
covering 64 i64 priorities, 128 i64 pagoda links, eight queue roots, two
64-entry branch stacks, and scalar scratch.

The primary has `O(m*n + m^2)` worst-case trace time and `O(n)` workspace:
each bottom-up meld visits at most `n` nodes and priority uniqueness checks
scan the at-most-`m` inserted keys. The independent sorted-queue model has
`O(m*n + m^2)` time and `O(n+q)` workspace. Here `m<=64`, `n<=64`, and
`q<=8`.

The original paper defines MIN, INSERT, EXTRACTMIN, and destructive UNION.
INSERT is the union of a queue and a singleton. For EXTRACTMIN, its §3.4
renames the two root subtrees and joins them in `D+G` order; this profile
therefore melds the right subtree before the left subtree after removing a
root. The workload exercises branch melds, destructive source clearing,
empty melds, minimum queries, extraction, malformed fields, uniqueness, the
maximum frame and node count, and a long right-extreme branch.

| Language | Port |
|---|---|
| C | [c/p/pagoda_meldable_priority_queue.c](../../../c/p/pagoda_meldable_priority_queue.c) |
| C3 | [c3/p/pagoda_meldable_priority_queue.c3](../../../c3/p/pagoda_meldable_priority_queue.c3) |
| C++ | [cpp/p/pagoda_meldable_priority_queue.cpp](../../../cpp/p/pagoda_meldable_priority_queue.cpp) |
| Elisa | [elisa/p/pagoda_meldable_priority_queue.elisa](../../../elisa/p/pagoda_meldable_priority_queue.elisa) |
| Mojo | [mojo/p/pagoda_meldable_priority_queue.mojo](../../../mojo/p/pagoda_meldable_priority_queue.mojo) |
| Nim | [nim/p/pagoda_meldable_priority_queue.nim](../../../nim/p/pagoda_meldable_priority_queue.nim) |
| Odin | [odin/p/pagoda_meldable_priority_queue.odin](../../../odin/p/pagoda_meldable_priority_queue.odin) |
| Rust | [rust/p/pagoda_meldable_priority_queue.rs](../../../rust/p/pagoda_meldable_priority_queue.rs) |
| V | [v/p/pagoda_meldable_priority_queue.v](../../../v/p/pagoda_meldable_priority_queue.v) |
| Zig | [zig/p/pagoda_meldable_priority_queue.zig](../../../zig/p/pagoda_meldable_priority_queue.zig) |

The profile follows the structure and operation semantics in Francon,
Viennot, and Vuillemin, [*Description and Analysis of an Efficient Priority
Queue Representation*](https://www.xavierviennot.org/xavier/articles_files/FrViVu78.pdf),
§§1 and 3, and the pointer-layout summary in [NIST DADS](https://xlinux.nist.gov/dads/HTML/pagoda.html).
Implementations and fixtures are independently authored from those
descriptions; no published source code, prose, or tests are reused.
