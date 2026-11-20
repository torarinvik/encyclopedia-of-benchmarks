# Hash heap priority-queue trace

This benchmark profiles a bounded priority queue whose keys are mapped by a
monotone function into ordered buckets, with one min-heap in each bucket. The
first nonempty bucket contains the global minimum; extracting from that bucket
repairs only its local heap.

## Profile contract

The `i64_array_bytes_output` input is
`[U,B,q,(opcode,operand)*q]`. The key universe is `0 <= key < U`, with
`1 <= U <= 128`, `1 <= B <= min(U,8)`, and at most 64 operations. The exact
frame length is `3+2q`: 131 words are valid and 132 are parseable so a trailing
word can be rejected.

The profile pins the order-preserving map `bucket(key)=floor(key*B/U)` and a
stable item order `(key, zero-based insertion-operation index)`. Opcode 0
inserts its key; opcode 1 peeks at the minimum; opcode 2 extracts the minimum.
Query operands must be zero. A successful insert emits `-2`; an empty query
emits `-1`; a successful query emits `(insertion_index << 8) | key`. The output
is `[q,result_0,...,result_(q-1)]` as little-endian signed-i64 words, including
an 8-byte zero header when `q=0`. The maximum output is 520 bytes. Malformed
input returns `-1`; null output or insufficient capacity returns `-2` after
full input validation, and errors leave the caller's buffer untouched.

The fixed profile arena supports up to 64 items even when all fall into one
bucket, so bucket-full behavior does not occur. Each operation costs
`O(B + log(q+1))` in the heap implementation: finding the first nonempty bucket
scans at most `B` lanes, and insertion/extraction repairs one heap of size at
most `q`. The full trace is `O(q(B + log(q+1)))`; the independent flat-list model
uses `O(q)` work per query/extraction and `O(q^2)` for a trace. The heap model
uses `O(Bq+q)` storage, while the independent model uses `O(q)` storage.
Workspace is capped at 4,096
bytes, including eight fixed key/index heap lanes (1,024 payload bytes),
operation staging, lane sizes, output/result staging, scalar locals, and call
frames.

## Algorithm and source

NIST DADS defines a hash heap as an order-preserving linear hash from keys to
buckets, with each bucket implemented as a heap. DADS notes that the original
proposal did not specify what happens when a bucket fills; this profile avoids
that ambiguity with a total operation cap and fixed arena. The particular
floor mapping, min-heap orientation, stable tie rule, and three-op query
protocol are explicit benchmark profile choices, not claims about the original
proposal. The primary uses per-bucket binary min-heaps. The independent
reference scans a flat live-item list to find each query result.

Sources:

- [NIST DADS, Hash heap](https://xlinux.nist.gov/dads/HTML/hashheap.html),
  which attributes the proposal to Chris L. Kuszmaul's 13 January 1999
  `comp.theory` post.
- [NIST DADS, Linear hash](https://xlinux.nist.gov/dads/HTML/linearhash.html)
  for the order-preserving mapping property.

The referenced original Usenet post was not located. Only the algorithm
description was used; no source code, examples, or prose were copied. See
[`RIGHTS.md`](RIGHTS.md).

## Workload and references

[`workload.json`](workload.json) covers ordered buckets, duplicate-key stable
ties, empty peeks/extracts, exact maximum input/output, a maximum one-byte-short
buffer, a maximum parseable trailing frame, malformed operands, null pointers,
and the zero-operation output header. Every case pins its expected little-endian
output as hex, including the full 520-byte maximum result and empty hex for
error cases. `primary_oracle.py` models bucket heaps;
`independent_oracle.py` uses a direct scan of all live items. The workload
helper compares both references and their exact output words.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/h/hash_heap_priority_queue_trace.c`](../../../c/h/hash_heap_priority_queue_trace.c) |
| C3 | [`c3/h/hash_heap_priority_queue_trace.c3`](../../../c3/h/hash_heap_priority_queue_trace.c3) |
| C++ | [`cpp/h/hash_heap_priority_queue_trace.cpp`](../../../cpp/h/hash_heap_priority_queue_trace.cpp) |
| Elisa | [`elisa/h/hash_heap_priority_queue_trace.elisa`](../../../elisa/h/hash_heap_priority_queue_trace.elisa) |
| Mojo | [`mojo/h/hash_heap_priority_queue_trace.mojo`](../../../mojo/h/hash_heap_priority_queue_trace.mojo) |
| Nim | [`nim/h/hash_heap_priority_queue_trace.nim`](../../../nim/h/hash_heap_priority_queue_trace.nim) |
| Odin | [`odin/h/hash_heap_priority_queue_trace.odin`](../../../odin/h/hash_heap_priority_queue_trace.odin) |
| Rust | [`rust/h/hash_heap_priority_queue_trace.rs`](../../../rust/h/hash_heap_priority_queue_trace.rs) |
| V | [`v/h/hash_heap_priority_queue_trace.v`](../../../v/h/hash_heap_priority_queue_trace.v) |
| Zig | [`zig/h/hash_heap_priority_queue_trace.zig`](../../../zig/h/hash_heap_priority_queue_trace.zig) |
