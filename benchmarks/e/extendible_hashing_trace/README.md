# Extendible hashing trace

This benchmark replays inserts, deletes, and membership queries against an
extendible hash table with a bounded directory and capacity-2 buckets. It
measures the characteristic local bucket split, conditional directory
doubling, buddy coalescing, and directory shrinking. It is distinct from
`linear_hashing_trace`: that profile grows by advancing a split pointer one
bucket at a time; this profile uses per-bucket local depth and directory
aliases.

## Contract

The input is `[Q,(opcode,key)*Q]`, where `0 <= Q <= 40`, opcode 0 inserts an
absent key, opcode 1 deletes a present key, and opcode 2 queries membership.
Keys are bytes in `0..255`; the deterministic hash is `h(key)=key`, with the
lowest `global_depth` bits selecting a directory entry. The table starts with
global depth 1 and two empty buckets, each at local depth 1. Each bucket holds
at most two keys. A successful insert, delete, or present membership query
contributes one success bit; failed operations contribute zero. Inserting a
key already present is a failed no-op.

An overflowing bucket splits on the next low-order key bit. The directory
doubles only when that bucket's local depth equals global depth. After a
successful deletion, same-depth buddies merge when their combined contents
fit in one bucket; the lower suffix-prefix bucket survives. Repeated merges
continue upward, and mirrored directory halves shrink global depth, never
below one. Bucket IDs are internal and reused from the lowest free ID. The
maximum depth is a high-water value across the trace.

The signed-i64 result packs operation success bits in bits 0–39, final bucket
count in bits 40–48, final global depth in bits 49–52, maximum depth in bits
53–56, and final live-key count in bits 57–62. Success bits follow operation
order, with the oldest operation at the most-significant used bit. Valid
inputs contain at most 81 words; 82 words are parseable so a trailing word
can be rejected. Null, malformed, or mismatched frames return `-1`. A valid
empty trace returns the packed initial state. The conservative packed-result
upper bound from the field widths and profile caps is 5,841,451,291,187,871,743.

There are at most 40 operations and eight split/merge levels. Each directory
pass scans at most 256 entries, and each split moves at most two stored keys.
The conservative time bound is `O(Q*8*256)` (or `O(Q*256)` with the fixed
depth cap); state is `O(256)`. The declared workspace cap is 8,192 bytes. The
bounded domain makes global depth 8 sufficient: all eight hash bits
distinguish every valid key.

## References and duplicate check

NIST DADS describes directory indexing by low-order key/hash bits, bucket
splitting, directory doubling when a single bucket remains the overflow
target, and merging/shrinking after deletion. The primary citation is Fagin,
Nievergelt, Pippenger, and Strong, [“Extendible Hashing – A Fast Access
Method for Dynamic Files”](https://doi.org/10.1145/320083.320092), ACM TODS
4(3), 315–344 (1979). See [RIGHTS.md](RIGHTS.md) for provenance.

The primary reference models an explicit directory and fixed bucket slots.
The independent reference models a partition of low-bit prefixes and splits
or merges prefix buckets directly. They share only the input/output contract.
Fixtures are hand-derived from the stated profile.

## Package files

- [Workload](workload.json)
- [Primary reference](primary_oracle.py)
- [Independent reference](independent_oracle.py)
- [Workload validator](verify_workload.py)
- [Static inventory checker](check_inventory.py)
- [Inventory](INVENTORY.md) and [machine-readable inventory](INVENTORY.json)

## Language ports

| Language | Source |
|---|---|
| C | [`c/e/extendible_hashing_trace.c`](../../../c/e/extendible_hashing_trace.c) |
| C3 | [`c3/e/extendible_hashing_trace.c3`](../../../c3/e/extendible_hashing_trace.c3) |
| C++ | [`cpp/e/extendible_hashing_trace.cpp`](../../../cpp/e/extendible_hashing_trace.cpp) |
| Elisa | [`elisa/e/extendible_hashing_trace.elisa`](../../../elisa/e/extendible_hashing_trace.elisa) |
| Mojo | [`mojo/e/extendible_hashing_trace.mojo`](../../../mojo/e/extendible_hashing_trace.mojo) |
| Nim | [`nim/e/extendible_hashing_trace.nim`](../../../nim/e/extendible_hashing_trace.nim) |
| Odin | [`odin/e/extendible_hashing_trace.odin`](../../../odin/e/extendible_hashing_trace.odin) |
| Rust | [`rust/e/extendible_hashing_trace.rs`](../../../rust/e/extendible_hashing_trace.rs) |
| V | [`v/e/extendible_hashing_trace.v`](../../../v/e/extendible_hashing_trace.v) |
| Zig | [`zig/e/extendible_hashing_trace.zig`](../../../zig/e/extendible_hashing_trace.zig) |

The scalar runner/verifier and catalog register this profile. All integration
review remained source-only; no programs, tests, scripts, checkers, builds,
compilers, profilers, or benchmarks were run.
