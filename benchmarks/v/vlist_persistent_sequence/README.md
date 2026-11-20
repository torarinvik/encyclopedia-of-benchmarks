# Bagwell VList persistent sequence

This package benchmarks a bounded VList operation trace based on Phil
Bagwell's geometric-block functional list. A version root is a `(block,offset)`
pair. A block stores a contiguous segment, its `LastUsed` offset, and the prior
root to follow at the block boundary. Block capacities double from one. The
ports retain all root pairs, so old versions remain queryable after later
prepends.

## Contract

The ABI is `i64_array_bytes_output`. Input is `[Q,(tag,root,arg)*Q]`, with
`1<=Q<=48`. Values are in `[-1,000,000,1,000,000]`; at most 32 cons operations
are allowed. Root 0 is the empty list.

| Tag | Record | Meaning | Output word |
|---:|---|---|---|
| 0 | `(0,latest_root,value)` | Prepend `value`, creating the next root ID. Cons operations must form a linear chain and all occur before queries. | New root ID |
| 1 | `(1,root,-1)` | Create a persistent cdr root. The source root must be nonempty. | New root ID |
| 2 | `(2,root,index)` | Read the zero-based element from the head. | Element |
| 3 | `(3,root,-1)` | Compute list length by traversing block offsets. | Length |

Each operation emits one little-endian signed i64 word. The maximum valid input
is 145 words, the one-extra-word parseable frame is 146 words, and maximum
output is 384 bytes. Malformed input returns `-1`; a valid null output or short
capacity returns `-2` without writing. The fixed workspace cap is 4,096 bytes.

The workload grows a linear cons history across capacities `1,2,4,8,16,32`,
then queries saved roots and cdr-derived roots across block boundaries. It does
not prepend after the query phase. Thus the tested persistence property is
explicit: every earlier `(block,offset)` root remains readable while newer
elements occupy only later unused slots. Branch-prepend is outside this profile.

The primary oracle models block descriptors, offsets, and block traversal. The
independent oracle stores immutable tuples per root and interprets the same
operation trace without modeling blocks. The block model takes O(N+Q log N)
time; the tuple model takes O(QN) time from copying retained versions. Native
workspace is O(N+Q), while the independent oracle retains O(QN) tuple entries.
See
[`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and
[`INVENTORY.md`](INVENTORY.md).

## Duplicate review

This is distinct from `measured_finger_tree_sequence`, which uses a measured
2–3 finger tree and supports measure-guided splits and concatenation. The local
persistent queue and persistent segment-tree profiles also use different
representations and operation sets. This profile specifically follows
Bagwell's geometrically growing linked blocks and `(block,offset)` roots for
persistent prepend, cdr, nth, and length operations.

The primary source is Bagwell's [EPFL technical report, *Fast Functional
Lists, Hash-Lists, Deques and Variable Length Arrays*](https://lampwww.epfl.ch/papers/techlists.pdf),
especially §§2.1, 2.3, and 2.5. The RosettaGit [VList title page](https://rosettagit.org/tasks/vlist/)
was used only to discover the topic; no submission or protected task material
was used.

## Implementations

| Language | Source |
|---|---|
| C | [`c/v/vlist_persistent_sequence.c`](../../../c/v/vlist_persistent_sequence.c) |
| C3 | [`c3/v/vlist_persistent_sequence.c3`](../../../c3/v/vlist_persistent_sequence.c3) |
| C++ | [`cpp/v/vlist_persistent_sequence.cpp`](../../../cpp/v/vlist_persistent_sequence.cpp) |
| Elisa | [`elisa/v/vlist_persistent_sequence.elisa`](../../../elisa/v/vlist_persistent_sequence.elisa) |
| Mojo | [`mojo/v/vlist_persistent_sequence.mojo`](../../../mojo/v/vlist_persistent_sequence.mojo) |
| Nim | [`nim/v/vlist_persistent_sequence.nim`](../../../nim/v/vlist_persistent_sequence.nim) |
| Odin | [`odin/v/vlist_persistent_sequence.odin`](../../../odin/v/vlist_persistent_sequence.odin) |
| Rust | [`rust/v/vlist_persistent_sequence.rs`](../../../rust/v/vlist_persistent_sequence.rs) |
| V | [`v/v/vlist_persistent_sequence.v`](../../../v/vlist_persistent_sequence.v) |
| Zig | [`zig/v/vlist_persistent_sequence.zig`](../../../zig/v/vlist_persistent_sequence.zig) |

`check_inventory.py` checks package files and the ten port paths without
building or running implementations. `verify_workload.py` statically reconciles
the pinned fixtures against both references.
