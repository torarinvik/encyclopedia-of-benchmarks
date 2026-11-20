# Counting Bloom filter operation trace

This package profiles the deletion-capable counting Bloom filter. Its central
state is a fixed array of counters: insertion increments the hashed positions,
deletion decrements those same positions, and membership succeeds only when
all queried counters are nonzero.

## Contract

Input is `[Q,(opcode,key)*Q]`, where `0<=Q<=64`, opcodes are `0=insert`,
`1=delete`, and `2=query`, and keys lie in `0..65535`. The exact frame length
is `1+2Q`; the largest valid input has 129 signed-i64 words and the parser
accepts up to 130 words before exact-frame validation. The empty trace is
valid.

The filter starts with 67 zeroed byte counters. Four distinct positions for a
key `x` use the deterministic profile
`h0=(17*x+3) mod 67`, `step=1+((5*x+3) mod 66)`, and
`hj=(h0+j*step) mod 67` for `j=0,1,2,3`. Since 67 is prime and `step` is
nonzero, those four positions are distinct. The fixed arithmetic makes the
workload reproducible; it does not claim a probabilistic false-positive bound.

Insert increments all four counters. Delete decrements all four counters and
has the caller precondition that the key currently occurs in the represented
multiset; the filter does not keep an exact key set to check this precondition.
Duplicate inserts represent duplicate occurrences, and a valid delete removes
one occurrence. Query emits `1` iff all four counters are nonzero, otherwise
`0`. Every operation emits one raw status byte (`1` for insert/delete and the
membership bit for query). Update bytes acknowledge the replay operation and
are a benchmark framing choice, not an output defined by the source paper. The
maximum output is 64 bytes. Malformed framing, opcode, or key returns `-1`; null output or
insufficient capacity returns `-2`, after input validation. Errors write no
bytes. Workspace is capped at 1,024 bytes; the mutable filter state itself is
67 bytes.

The primary reference updates the counter vector directly. The independent
reference retains signed key events and rebuilds counter values from that
history when answering queries. This profile extends the local
[`bloom_filter`](../../b/bloom_filter/README.md), which uses a bit array and
does not support deletion. Local cuckoo, quotient, XOR, and invertible Bloom
filters have different fingerprints, layouts, or reconciliation behavior.

Each insert, delete, and query uses four counter positions, so time is O(k)
with fixed `k=4` and the filter uses O(m) counters with fixed `m=67`. The
reference-side exact multiset is not part of the native workload.

## Provenance and rights

The counted-position update follows Fan, Cao, Almeida, and Broder,
“Summary Cache: A Scalable Wide-Area Web Cache Sharing Protocol,” SIGCOMM
1998, §4.3, [DOI 10.1145/285243.285287](https://doi.org/10.1145/285243.285287).
The journal version is [DOI 10.1109/90.851975](https://doi.org/10.1109/90.851975).
The [NIST DADS Bloom filter entry](https://xlinux.nist.gov/dads/HTML/bloomFilter.html)
was used for discovery; the counting extension's algorithmic definition is
from the paper. Yale's *Notes on Randomized Algorithms*, §7.6.5, provides an
independent description of replacing bits with counters and returning
membership from the hashed locations. Sources provide algorithm descriptions
only: no code, prose, examples, or fixtures are reused. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/counting_bloom_filter_operation_trace.c`](../../../c/c/counting_bloom_filter_operation_trace.c) |
| C3 | [`c3/c/counting_bloom_filter_operation_trace.c3`](../../../c3/c/counting_bloom_filter_operation_trace.c3) |
| C++ | [`cpp/c/counting_bloom_filter_operation_trace.cpp`](../../../cpp/c/counting_bloom_filter_operation_trace.cpp) |
| Elisa | [`elisa/c/counting_bloom_filter_operation_trace.elisa`](../../../elisa/c/counting_bloom_filter_operation_trace.elisa) |
| Mojo | [`mojo/c/counting_bloom_filter_operation_trace.mojo`](../../../mojo/c/counting_bloom_filter_operation_trace.mojo) |
| Nim | [`nim/c/counting_bloom_filter_operation_trace.nim`](../../../nim/c/counting_bloom_filter_operation_trace.nim) |
| Odin | [`odin/c/counting_bloom_filter_operation_trace.odin`](../../../odin/c/counting_bloom_filter_operation_trace.odin) |
| Rust | [`rust/c/counting_bloom_filter_operation_trace.rs`](../../../rust/c/counting_bloom_filter_operation_trace.rs) |
| V | [`v/c/counting_bloom_filter_operation_trace.v`](../../../v/c/counting_bloom_filter_operation_trace.v) |
| Zig | [`zig/c/counting_bloom_filter_operation_trace.zig`](../../../zig/c/counting_bloom_filter_operation_trace.zig) |

The workload, two references, rights note, and package-local static inventory
are included. The package is registered in the byte-output runner and
verifier, README, and catalog. No programs, tests, scripts, helpers/checkers, builds, compilers,
profilers, or benchmarks were run.
