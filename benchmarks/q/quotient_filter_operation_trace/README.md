# Standard quotient filter operation trace

`quotient_filter_operation_trace` benchmarks a bounded standard quotient
filter (SQF) update trace. It uses the classic three metadata bits:
`occupied`, `continuation`, and `shifted`. The online table stores sorted
remainder runs in eight circular slots. The profile is deterministic and
receives fingerprints directly, so it measures quotient/run placement and
metadata maintenance without a hash function or random seed.

## Contract

The exported `quotient_filter_operation_trace` function uses the
`i64_array_bytes_output` ABI. Input is `[Q,(opcode,fingerprint)*Q]`, where
`0 <= Q <= 32`, `opcode` is `0` (insert), `1` (lookup), or `2` (delete), and
`fingerprint` is an unsigned byte in `[0,255]`. The upper three bits are the
quotient and select one of eight canonical slots; the lower five bits are the
stored remainder. The valid input bound is 65 signed-i64 words, with 66 words
parseable for the one-extra-word rejection case.

This profile follows the original quotient filter's multiset interpretation:
each insert adds one copy, including duplicate fingerprints. Equal remainders
stay adjacent in their run, and a new equal copy is placed after existing
equal copies. Lookup reports whether at least one copy exists. Delete removes
the first matching copy from the sorted run; deleting an absent fingerprint
does nothing. The table accepts at most six total copies. An insert at that
limit returns status `2` and leaves the table unchanged; otherwise insert
returns `1`. Lookup and delete return `1` for present/removed and `0` for
absent. The trace continues after a full-table status.

The table has no multiplicity counters: repeated fingerprints occupy repeated
run slots. The occupied bit remains indexed by canonical quotient; remainder,
continuation, and shifted bits describe the entry currently stored in each
slot. Existing runs are located by the Figure 3 cluster walk: scan backward
from the quotient through shifted slots to the cluster anchor, then advance
through continuation-delimited runs while advancing the bucket cursor through
occupied bits. To position a new quotient inside a cluster, the same walk stops
when the bucket cursor reaches that quotient and returns the next run head.
This reads the three metadata arrays directly; it does not reconstruct a
per-slot quotient map.

Insert finds the first remainder strictly greater than the new one, so equal
copies are placed after existing equals. It shifts entries right only as far
as the next empty slot. If insertion is before an existing run head, the old
head becomes a continuation; the new entry is a continuation exactly when it
is inserted inside an existing run. Every shifted entry is marked shifted,
and occupied bits stay at their canonical indices. Delete removes the first
matching copy in the sorted run. If that copy is a run head and another copy
of the quotient follows, that next entry is promoted to the head. If the run
ends, its occupied bit is cleared. The resulting hole moves left through
shifted entries only, stopping at an empty slot or an unshifted entry at its
home slot. While run heads move, their home quotient is advanced using the
occupied bits; continuation and shifted flags are written directly for each
moved slot. Wraparound uses modulo eight throughout.

The duplicate policy follows Bender et al.'s explicit multiset definition.
Geil et al.'s GPU insertion pseudocode also returns early on an equal
remainder; this profile keeps the multiset behavior and uses the paper's
metadata-guided run traversal and bounded local-shift model. The wire output
contains only one status byte per operation, not the final slot array.

Malformed framing, opcodes, or fingerprints return `-1` without output. A
null output pointer or capacity below `Q` returns `-2`, also without output;
input validation precedes output-capacity handling. The maximum successful
output is 32 bytes. Workspace is capped at 256 bytes, including the eight-slot
remainder and three metadata arrays, 32-byte status staging, and scalar
bookkeeping. For `Q` operations, the primary uses `O(Q*8)` bounded time for
metadata-guided cluster walks and local shifts and `O(8+Q)` storage; the
independent multiset reference uses expected `O(Q)` time and `O(6)` state.

## References and distinction

The primary operation rules follow Bender et al.'s standard quotient filter:
fingerprints split into quotient and remainder, sorted remainder runs, the
three metadata bits, circular shifting, and multiset insert/delete behavior
([paper](https://doi.org/10.14778/2350229.2350275), §3 and Figure 3). Geil,
Farach-Colton, and Owens provide a second description of the standard SQF's
cluster/run lookup and serial insert/delete traversal
([paper](https://doi.org/10.1109/IPDPS.2018.00055), §III-A, Algorithms 1 and
3). This package does not implement the rank/select quotient filter, a
counting quotient filter, or the GPU bulk-build variants.

The structure is distinct from local Bloom filters (bit-array membership),
cuckoo filters (alternate-bucket relocation), XOR filters (static graph
peeling), and IBLTs (signed-cell set reconciliation). No source code, prose,
examples, or fixtures are reused.

## Language ports

- [C](../../../c/q/quotient_filter_operation_trace.c)
- [C3](../../../c3/q/quotient_filter_operation_trace.c3)
- [C++](../../../cpp/q/quotient_filter_operation_trace.cpp)
- [Elisa](../../../elisa/q/quotient_filter_operation_trace.elisa)
- [Mojo](../../../mojo/q/quotient_filter_operation_trace.mojo)
- [Nim](../../../nim/q/quotient_filter_operation_trace.nim)
- [Odin](../../../odin/q/quotient_filter_operation_trace.odin)
- [Rust](../../../rust/q/quotient_filter_operation_trace.rs)
- [V](../../../v/q/quotient_filter_operation_trace.v)
- [Zig](../../../zig/q/quotient_filter_operation_trace.zig)

## Package files

- `primary_oracle.py`: bounded physical SQF reference.
- `independent_oracle.py`: abstract fingerprint-multiset reference.
- `workload.json`: pinned ABI and trace fixtures.
- `verify_workload.py`: static dual-reference fixture reconciliation.
- `check_inventory.py`: source-path and metadata inventory checks.
- `RIGHTS.md`: source provenance and clean-room notes.

The profile is registered with the shared `i64_array_bytes_output` runner
and verifier, catalog, and root README. No programs, tests, scripts,
helpers/checkers, builds, compilers, profilers, or benchmarks were run.
