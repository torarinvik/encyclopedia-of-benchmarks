# Interval heap with double-ended operations

This package implements the interval-heap DEPQ described by van Leeuwen and Wood. Each node stores a low and high key (the last node may contain one key); each child interval is contained in its parent interval. The low endpoints form a min-heap and the high endpoints form a max-heap. The existing `min_max_heap_double_ended` uses alternating min and max levels, so it is a different storage and repair method despite sharing the same abstract operations.

## Bounded trace contract

The `i64_array_bytes_output` entry point accepts `[initial_count, initial_values..., operation_count, (opcode, argument)...]`. Initial and inserted keys are signed 32-bit integers. There are at most 64 initial keys and 128 operations, so at most 192 keys can be live. Initial keys are inserted in input order into an initially empty interval heap.

| Opcode | Operation | Argument | Event result |
| --- | --- | --- | --- |
| 0 | `Insert(argument)` | signed i32 key | none |
| 1 | `FindMin()` | 0 | minimum key |
| 2 | `FindMax()` | 0 | maximum key |
| 3 | `ExtractMin()` | 0 | removed minimum key |
| 4 | `ExtractMax()` | 0 | removed maximum key |
| 5 | `Count` | 0 | current key count |

The input length must be exactly `initial_count + 2 + 2 * operation_count` and cannot exceed 322 signed 64-bit words. Empty find/extract operations, malformed frames, out-of-range keys, unknown opcodes, and nonzero arguments on opcodes 1–5 return `-1`. A valid trace with a null output buffer or insufficient capacity returns `-2` and writes no bytes. These errors are checked before output is written.

Success returns a little-endian signed-i64 vector `[event_count, event_results..., final_count, final_keys_sorted_ascending...]`. Equal keys remain separate; because the trace exposes keys and counts but no entry identities, equal-key ordering is observationally indistinguishable. Sifts use strict comparisons and select the left child on equal child endpoints. The maximum possible successful output is 1,552 bytes: at most 64 initial keys plus 128 operation contributions (an insertion contributes a final key, a query/count contributes an event, and an extraction contributes one event while removing one key), plus two framing words. Ports use at most 8,192 bytes of bounded workspace.

## Workload and references

[`workload.json`](workload.json) pins empty and singleton cases, both endpoint queries and extractions, duplicates, signed-i32 limits, invalid traces, null pointers, a one-byte-short simple output, and a one-byte-short maximum-frame output. [`primary_oracle.py`](primary_oracle.py) follows the paired-endpoint interval-heap operations. [`independent_oracle.py`](independent_oracle.py) uses a sorted multiset and does not reproduce the heap structure.

## Provenance

The data structure and operation profile follow Sections 1–2 of van Leeuwen and Wood's article and its primary-author technical-report description. The NIST DADS entry supplied the discovery category. A modern pseudocode description is used only as a behavioral cross-check; no source code, comments, prose, or fixtures are reused.

- J. van Leeuwen and D. Wood, “Interval Heaps,” *The Computer Journal* 36(3), 209–216 (1993), [DOI 10.1093/comjnl/36.3.209](https://doi.org/10.1093/comjnl/36.3.209).
- J. van Leeuwen and D. Wood, primary-author technical report, “Interval Heaps,” [CS-1987/1987-01](https://ics-archive.science.uu.nl/research/techreps/repo/CS-1987/1987-01.pdf), Sections 1–2.
- Paul E. Black, [NIST DADS: double-ended priority queue](https://xlinux.nist.gov/dads/HTML/doubleendpq.html).
- Behavioral cross-check: [Interval heap operation description](https://algorithm.tamnd.com/interval-heap/). Its implementation and examples are not reused.

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/i/interval_heap_double_ended.c`](../../../c/i/interval_heap_double_ended.c) |
| C3 | [`c3/i/interval_heap_double_ended.c3`](../../../c3/i/interval_heap_double_ended.c3) |
| C++ | [`cpp/i/interval_heap_double_ended.cpp`](../../../cpp/i/interval_heap_double_ended.cpp) |
| Elisa | [`elisa/i/interval_heap_double_ended.elisa`](../../../elisa/i/interval_heap_double_ended.elisa) |
| Mojo | [`mojo/i/interval_heap_double_ended.mojo`](../../../mojo/i/interval_heap_double_ended.mojo) |
| Nim | [`nim/i/interval_heap_double_ended.nim`](../../../nim/i/interval_heap_double_ended.nim) |
| Odin | [`odin/i/interval_heap_double_ended.odin`](../../../odin/i/interval_heap_double_ended.odin) |
| Rust | [`rust/i/interval_heap_double_ended.rs`](../../../rust/i/interval_heap_double_ended.rs) |
| V | [`v/i/interval_heap_double_ended.v`](../../../v/i/interval_heap_double_ended.v) |
| Zig | [`zig/i/interval_heap_double_ended.zig`](../../../zig/i/interval_heap_double_ended.zig) |

No programs, tests, scripts, checkers, builds, compilers, profilers, or benchmarks were run while drafting this package.
