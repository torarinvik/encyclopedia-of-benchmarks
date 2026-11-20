# Cuckoo Filter operation trace

This package isolates the fingerprint-only cuckoo filter operations: insert a
fingerprint, query membership, and delete one fingerprint copy. It follows the
partial-key cuckoo relocation scheme while pinning deterministic tie choices so
the bounded replay is reproducible.

## Bounded contract

Input is `[Q,(opcode,primary_bucket,fingerprint)*Q]`. `Q` is 1 through 32. Each
operation record has exactly three signed i64 fields: opcode `0` inserts, `1`
queries, and `2` deletes; `primary_bucket` is in `0..7`; and the nonzero
fingerprint is in `1..15`. The pair `(primary_bucket,fingerprint)` is the
caller-supplied prehashed item descriptor. The original item is not stored.

The table contains eight buckets with four slots each. For fingerprint `f`,
define `delta(f)=1+((5*f+3) mod 7)`, and let the alternate bucket of bucket `i`
be `i xor delta(f)`. This delta is nonzero, so each descriptor has two
distinct candidate buckets. Empty slots are represented internally by zero.

An insert first places the fingerprint in the lowest empty slot of the primary
bucket, if one exists, then does the same in the alternate bucket. If both are
full, begin at the primary bucket. For at most eight kicks, replace the
lowest-numbered slot in the current bucket with the pending fingerprint,
carry the evicted fingerprint to `current xor delta(evicted)`, and append it
to the lowest empty slot there if available. If the destination is full, it is
the next current bucket. The first insertion that exhausts all eight kicks
aborts the whole trace with `-3` and no output. This pinned deterministic
eviction policy replaces the source algorithm's random choices; no random
success guarantee is claimed.

Lookup checks the primary bucket and then the alternate bucket, scanning slots
from lowest to highest. Delete uses the same bucket and slot order and removes
one matching fingerprint. Because the table does not retain original keys,
delete records are in-domain only when they refer to a previously inserted
descriptor copy that has not already been deleted. Duplicate insertions are
stored as multiple fingerprint copies, up to the natural table capacity.

Each successful operation emits one status i64: insert success is `1`, lookup
returns `1` or `0`, and delete returns `1` or `0`. Statuses are serialized as
eight-byte little-endian signed integers. Invalid framing/fields return `-1`;
after input validation, null output or insufficient capacity returns `-2`;
an insertion that reaches the kick cap returns `-3`. Errors write no output.
The maximum valid input is 97 words, the parser accepts up to a 98-word
boundary before checking exact framing, maximum output is 256 bytes, and
workspace is capped at 1,024 bytes.

The primary reference mutates one flat slot array. The independent reference
stores bucket tuples and reconstructs a fresh bucket value for each eviction.
They use different table representations while following the same fixed
contract.

## Duplicate comparison

This differs from [`bloom_filter`](../../b/bloom_filter/README.md), whose bit
array supports membership but not deletion; [`xor_filter_peeling`](../../x/xor_filter_peeling/README.md),
which builds a static fingerprint assignment by graph peeling; and
[`hash_map_cuckoo_hashing`](../../h/hash_map_cuckoo_hashing/README.md), which
stores full keys in a cuckoo hash set. This profile stores only fingerprints,
derives the second bucket from the first bucket and fingerprint, and supports
approximate membership plus deletion.

## Provenance

The algorithmic source is Fan, Andersen, Kaminsky, and Mitzenmacher,
“Cuckoo Filter: Practically Better Than Bloom,” CoNEXT 2014, Sections 3.1–3.3.
The adjacent NIST DADS entries for [cuckoo hashing](https://xlinux.nist.gov/dads/HTML/cuckooHashing.html)
and [Bloom filters](https://xlinux.nist.gov/dads/HTML/bloomFilter.html) were
used for discovery and terminology. See [RIGHTS.md](RIGHTS.md) for the reuse
boundary.

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/cuckoo_filter_operation_trace.c`](../../../c/c/cuckoo_filter_operation_trace.c) |
| C3 | [`c3/c/cuckoo_filter_operation_trace.c3`](../../../c3/c/cuckoo_filter_operation_trace.c3) |
| C++ | [`cpp/c/cuckoo_filter_operation_trace.cpp`](../../../cpp/c/cuckoo_filter_operation_trace.cpp) |
| Elisa | [`elisa/c/cuckoo_filter_operation_trace.elisa`](../../../elisa/c/cuckoo_filter_operation_trace.elisa) |
| Mojo | [`mojo/c/cuckoo_filter_operation_trace.mojo`](../../../mojo/c/cuckoo_filter_operation_trace.mojo) |
| Nim | [`nim/c/cuckoo_filter_operation_trace.nim`](../../../nim/c/cuckoo_filter_operation_trace.nim) |
| Odin | [`odin/c/cuckoo_filter_operation_trace.odin`](../../../odin/c/cuckoo_filter_operation_trace.odin) |
| Rust | [`rust/c/cuckoo_filter_operation_trace.rs`](../../../rust/c/cuckoo_filter_operation_trace.rs) |
| V | [`v/c/cuckoo_filter_operation_trace.v`](../../../v/c/cuckoo_filter_operation_trace.v) |
| Zig | [`zig/c/cuckoo_filter_operation_trace.zig`](../../../zig/c/cuckoo_filter_operation_trace.zig) |

Package-local workload, independent references, rights, and static inventory
accompany the ports. The shared byte-output runner and verifier register the
primary and independent references, workspace and frame bounds, and all
fixtures.
