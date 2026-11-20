# 2-left hashing operation trace

This package profiles the asymmetric two-choice collision rule known as
2-left hashing. It uses two separate, equally sized bucket arrays with
separate-chaining lists. Each operation supplies the two already-computed
bucket indices, so the package measures placement and lookup behavior without
depending on a PRNG or an unstated hash family.

## Bounded contract

Input is `[Q,(opcode,key,left_bucket,right_bucket)*Q]`. `Q` is 1 through 40;
each record has four signed i64 words. Opcode `0` inserts, `1` queries, and `2`
deletes. Keys are in `0..63`, and each bucket index is in `0..7`. Repeated
records for the same key must supply the same pair of bucket indices. The
profile supports at most 32 live distinct keys.

There are two halves with eight buckets each. Every bucket is a linked list.
For a new key, compare the lengths of its left and right candidate chains and
insert into the shorter one; ties go to the left half. New list entries are
placed at the chain head. An insert of an existing key returns status `0` and
does not add another copy. A new insert returns status `1` and records its
chosen half (`0` left, `1` right). Lookup scans the left candidate chain then
the right candidate chain. Delete uses the same search order and removes the
matching key when present.

Each operation emits two little-endian i64 words: `[status,placement]`.
`status` is `1` or `0` for insert/lookup/delete success. `placement` is `0` or
`1` only for a new insertion and `-1` for all other operations. Invalid input
returns `-1`; after input validation, null output or insufficient capacity
returns `-2`; inserting a new key when 32 keys are already live aborts the
whole trace with `-3`. Errors write no output. The maximum valid input is 161
words, the parser boundary is 162 words, maximum output is 640 bytes, and
workspace is capped at 2,048 bytes.

The workload includes a 40-operation trace of absent-key lookups, which emits
exactly 640 bytes: each record is status `0` and placement `-1`.

The fixed hash indices are caller inputs, and this deterministic replay makes
no random-load or collision bound claim. The primary reference uses a bounded
linked-node pool and bucket heads; the independent reference stores nested
bucket lists and directly applies the least-loaded rule.

## Duplicate comparison

This differs from [`hash_map_cuckoo_hashing`](../../h/hash_map_cuckoo_hashing/README.md),
which evicts residents between alternate buckets; [`hash_map_hopscotch_hashing`](../../h/hash_map_hopscotch_hashing/README.md),
which relocates a free slot to preserve a bitmap neighborhood; and
[`hash_map_separate_chaining`](../../h/hash_map_separate_chaining/README.md),
which uses one candidate chain per key. 2-left compares two candidate chain
loads and resolves equal loads asymmetrically toward the left half.

## Provenance

The [NIST DADS 2-left hashing entry](https://xlinux.nist.gov/dads/HTML/twoLeftHashing.html)
defines the two equal-sized tables and the strict-right-only-if-less rule.
Vöcking's “How Asymmetry Helps Load Balancing,” *Journal of the ACM* 50(4),
568–589 (2003), analyzes the always-go-left tie policy. See
[RIGHTS.md](RIGHTS.md) for provenance and reuse details.

## Language ports

| Language | Source |
|---|---|
| C | [`c/t/two_left_hashing_operation_trace.c`](../../../c/t/two_left_hashing_operation_trace.c) |
| C3 | [`c3/t/two_left_hashing_operation_trace.c3`](../../../c3/t/two_left_hashing_operation_trace.c3) |
| C++ | [`cpp/t/two_left_hashing_operation_trace.cpp`](../../../cpp/t/two_left_hashing_operation_trace.cpp) |
| Elisa | [`elisa/t/two_left_hashing_operation_trace.elisa`](../../../elisa/t/two_left_hashing_operation_trace.elisa) |
| Mojo | [`mojo/t/two_left_hashing_operation_trace.mojo`](../../../mojo/t/two_left_hashing_operation_trace.mojo) |
| Nim | [`nim/t/two_left_hashing_operation_trace.nim`](../../../nim/t/two_left_hashing_operation_trace.nim) |
| Odin | [`odin/t/two_left_hashing_operation_trace.odin`](../../../odin/t/two_left_hashing_operation_trace.odin) |
| Rust | [`rust/t/two_left_hashing_operation_trace.rs`](../../../rust/t/two_left_hashing_operation_trace.rs) |
| V | [`v/t/two_left_hashing_operation_trace.v`](../../../v/t/two_left_hashing_operation_trace.v) |
| Zig | [`zig/t/two_left_hashing_operation_trace.zig`](../../../zig/t/two_left_hashing_operation_trace.zig) |

Package-local workload, references, rights, and static inventory accompany
the ports. The package is registered in the `i64_array_bytes_output` runner
and verifier and listed in the repository catalog.
