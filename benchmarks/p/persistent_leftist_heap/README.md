# Persistent leftist heap

This profile implements a min leftist heap whose updates preserve every prior
version. Melding copies only the selected roots along the right-spine merge
path, then restores the leftist null-path-length invariant on those copies.
Old roots and their descendants remain available to later branches. The local
[`leftist_heap`](../../l/leftist_heap/README.md) profile models two mutable
heaps and destructive donor merging; persistence and path copying are the
distinct operations measured here.

## Contract

Input is `[q, records...]`, with `0 <= q <= 64`. Version `0` is the empty heap.
Operation `i` may refer only to versions `0..i` and always creates version
`i+1`:

| Record | Operation |
|---|---|
| `[0, base, key]` | Insert `key` into a copy of `base` by melding with a singleton. |
| `[1, left, right]` | Meld the two referenced versions. |
| `[2, version]` | Remove and observe the minimum, creating the remaining heap. |
| `[3, version]` | Observe the minimum and create an alias version. |

Keys are in `[-10000,10000]`. Each produced heap may contain at most 128
elements; an operation exceeding that bound makes the whole input invalid.
Empty pop and peek operations observe a sentinel rank of `20001`; otherwise
the observed rank is `minimum + 10000`. The result is
`(sum_of_observed_ranks << 15) | xor_of_observed_ranks`, leaving enough low bits
for every possible observation rank. Malformed input returns
`-1`. At most 193 input words are valid; one extra parseable word is accepted
by the framing layer only so it can be rejected as trailing input. The pool
bound is 1024 nodes, including the empty sentinel, and the declared workspace
is 65,536 bytes.

The primary oracle uses path-copying leftist-heap nodes. The independent oracle
stores immutable sorted multisets for each version and performs meld, pop, and
peek directly. The workload covers branching, aliasing, duplicate roots,
empty heaps, the size ceiling, and malformed references.

The algorithm follows the persistent leftist-heap description in [OI Wiki's
persistent mergeable-heap article](https://oi-wiki.org/ds/persistent-heap/).
Only the algorithm idea was consulted; the contract, ports, oracles, and
fixtures are independently authored.

| Language | Port |
|---|---|
| C | [c/p/persistent_leftist_heap.c](../../../c/p/persistent_leftist_heap.c) |
| C3 | [c3/p/persistent_leftist_heap.c3](../../../c3/p/persistent_leftist_heap.c3) |
| C++ | [cpp/p/persistent_leftist_heap.cpp](../../../cpp/p/persistent_leftist_heap.cpp) |
| Elisa | [elisa/p/persistent_leftist_heap.elisa](../../../elisa/p/persistent_leftist_heap.elisa) |
| Mojo | [mojo/p/persistent_leftist_heap.mojo](../../../mojo/p/persistent_leftist_heap.mojo) |
| Nim | [nim/p/persistent_leftist_heap.nim](../../../nim/p/persistent_leftist_heap.nim) |
| Odin | [odin/p/persistent_leftist_heap.odin](../../../odin/p/persistent_leftist_heap.odin) |
| Rust | [rust/p/persistent_leftist_heap.rs](../../../rust/p/persistent_leftist_heap.rs) |
| V | [v/p/persistent_leftist_heap.v](../../../v/p/persistent_leftist_heap.v) |
| Zig | [zig/p/persistent_leftist_heap.zig](../../../zig/p/persistent_leftist_heap.zig) |
