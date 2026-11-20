# Partially retroactive priority queue

This bounded profile maintains a priority queue whose past operation at any
timeline position can be replaced. After each replacement it reports the
current queue's element count and sum. A replacement can change which earlier
insertions are removed by later minimum-deletions, so replaying a normal heap
is the independent reference, not the primary method.

## Contract

- Symbol: `partially_retroactive_priority_queue`; ABI: `i64_array_bytes_output`.
- Input: `[N,Q,(type,value)*N,(index,new_type,new_value)*Q]`.
- `1 <= N,Q <= 64`. Type `0` inserts a value in `[0,1_000_000]`; type `1`
  removes one minimum when nonempty; type `2` does nothing. Non-insert values
  must be `-1`. Each update uses a zero-based index and replaces both fields.
- Output contains one pair of signed 64-bit little-endian values per update:
  current element count followed by current sum. The largest output is 1,024
  bytes; maximum valid/parseable inputs are 322/323 signed 64-bit words.
- Invalid framing or values return `-1`. A valid call with a null or short
output buffer returns `-2`. Validation precedes the output-buffer check, and
errors write no output. The caller output buffer is capped at 1,024 bytes; a
separate conservative 16,384-byte bound covers the segment-tree state.

## Algorithm and references

The primary reference is a bounded segment-tree implementation of the
partially retroactive priority-queue method. Leaves represent historical
operations; each segment stores operation balance, prefix-minimum and
suffix-maximum balance, and the canonical unmatched insertion/deletion
indices. Bridge searches locate the interval in which an insertion and a
minimum-deletion can affect one another. Replacing an operation first undoes
its previous match, then installs the new operation and repairs only the
affected matches. Value ties use ascending operation value, then descending
insertion index for minimum-insertion selection and ascending deletion index
for maximum-deletion selection. The tie rule makes the matching trace
deterministic; equal values remain indistinguishable in the reported result.

The independent oracle rebuilds an ordinary min-heap from the complete
timeline after every update. It shares the semantics but not the dynamic
segment-tree state or bridge maintenance. Workload fixtures include operation
type changes, empty deletions, repeated priorities, and updates that alter
later matching.

The candidate task is in [Library Checker PR #1411](https://github.com/yosupo06/library-checker-problems/pull/1411),
from [issue #1213](https://github.com/yosupo06/library-checker-problems/issues/1213).
The PR is still open in the audited snapshot. Its task metadata is pinned at
commit `494ddf7a14d6e49759047a270aa37a1302592cbc`; this package uses the task
contract and algorithm descriptions only. The method reference is Demaine,
Iacono, and Langerman, [“Retroactive Data Structures”](https://doi.org/10.1145/1240233.1240236),
ACM Transactions on Algorithms 3(2), 2007. All implementations and fixtures
here are independently authored.

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), [`RIGHTS.md`](RIGHTS.md),
and [`INVENTORY.md`](INVENTORY.md). Shared `i64_array_bytes_output`
runner/verifier dispatch, package checks, and output-buffer sizing are
integrated in source. No executable package checks have been run.

## Language ports

[C](../../../c/p/partially_retroactive_priority_queue.c) ·
[C3](../../../c3/p/partially_retroactive_priority_queue.c3) ·
[C++](../../../cpp/p/partially_retroactive_priority_queue.cpp) ·
[Elisa](../../../elisa/p/partially_retroactive_priority_queue.elisa) ·
[Mojo](../../../mojo/p/partially_retroactive_priority_queue.mojo) ·
[Nim](../../../nim/p/partially_retroactive_priority_queue.nim) ·
[Odin](../../../odin/p/partially_retroactive_priority_queue.odin) ·
[Rust](../../../rust/p/partially_retroactive_priority_queue.rs) ·
[V](../../../v/p/partially_retroactive_priority_queue.v) ·
[Zig](../../../zig/p/partially_retroactive_priority_queue.zig)

These files are source drafts. No programs, tests, scripts, checkers, builds,
compilers, profilers, or benchmarks were run.
