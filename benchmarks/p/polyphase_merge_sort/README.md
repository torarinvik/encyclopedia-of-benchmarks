# Polyphase Merge Sort

This bounded profile sorts a signed 64-bit array by forming sorted runs of at
most eight values and merging them across three logical tapes. The first two
tapes receive an uneven Fibonacci-sized run distribution; empty dummy runs
fill any shortfall. Each phase merges one run from both input tapes until one
input is exhausted. That empty tape becomes the next output tape, while the
partially consumed runs remain in place on the other tapes. The final run is
copied back to the caller's array.

The `sort_call` ABI accepts arrays of 0 through 256 values and mutates the
input into ascending order. It uses fixed in-memory tape buffers to measure
the polyphase schedule; it does not perform disk or device I/O. The bounded
three-tape profile uses 7,008 bytes of fixed workspace. Input values may be
any signed 64-bit integers. Stability is not part of the output contract.
The run-descriptor arrays hold 34 entries per tape; the largest initial
Fibonacci quota is 21 runs on one tape and 34 across both input tapes.

This method is distinct from local [`external_merge_sorter`](../../e/external_merge_sorter/README.md),
which alternates sequential stores in balanced bottom-up passes. Polyphase
merge sort uses unequal run counts and rotates an emptied input file into the
output role. It is also distinct from local [`merge_ksorted_arrays`](../../m/merge_ksorted_arrays/README.md),
which only merges already sorted arrays and does not create runs or schedule
multiple tape phases.

The primary reference is bottom-up mergesort; the independent reference is
insertion sort. The workload includes dummy-run, duplicate, signed-boundary,
and run-size boundary cases. See [`RIGHTS.md`](RIGHTS.md),
[`INVENTORY.md`](INVENTORY.md), and [`workload.json`](workload.json).

`python3 benchmarks/verify_polyphase_merge_sort.py` checks the ports through
the shared `sort_call` checker and records each published workload length.
Its corpus includes exhaustive short arrays, the fixtures above, maximum-size
patterns, signed 64-bit boundaries, and seeded random arrays. This command is
provided for later verification; it has not been run.

The generic `sort_call` recorder is [`benchmarks/run_sort.py`](../../run_sort.py);
the dedicated verifier and the root catalog list this benchmark.

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/p/polyphase_merge_sort.c`](../../../c/p/polyphase_merge_sort.c) |
| C3 | [`c3/p/polyphase_merge_sort.c3`](../../../c3/p/polyphase_merge_sort.c3) |
| C++ | [`cpp/p/polyphase_merge_sort.cpp`](../../../cpp/p/polyphase_merge_sort.cpp) |
| Elisa | [`elisa/p/polyphase_merge_sort.elisa`](../../../elisa/p/polyphase_merge_sort.elisa) |
| Mojo | [`mojo/p/polyphase_merge_sort.mojo`](../../../mojo/p/polyphase_merge_sort.mojo) |
| Nim | [`nim/p/polyphase_merge_sort.nim`](../../../nim/p/polyphase_merge_sort.nim) |
| Odin | [`odin/p/polyphase_merge_sort.odin`](../../../odin/p/polyphase_merge_sort.odin) |
| Rust | [`rust/p/polyphase_merge_sort.rs`](../../../rust/p/polyphase_merge_sort.rs) |
| V | [`v/p/polyphase_merge_sort.v`](../../../v/p/polyphase_merge_sort.v) |
| Zig | [`zig/p/polyphase_merge_sort.zig`](../../../zig/p/polyphase_merge_sort.zig) |

NIST defines polyphase merge sort as a merge sort that reuses emptied
intermediate files. A detailed classic three-tape description appears in
R. L. Shores, [*System/360 Sorting Techniques*](https://ftpmirror.your.org/pub/misc/bitsavers/pdf/ibm/technical_information_exchange/Z77-7257_Shores_-_System_360_Sorting_Techniques_19671003.pdf),
§ “Polyphase Merge Sort,” pp. 18 and 43. This profile follows the
read-forward, two-input-tape version and its Fibonacci run distribution.
