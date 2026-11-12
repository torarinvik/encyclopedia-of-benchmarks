# Maximum frequency stack

This bounded online stack supports pushes and pops. A pop removes a value with
the highest current multiplicity; if several values share that multiplicity,
it removes the one whose latest still-active push happened most recently.

## Contract

Input is `[Q,(opcode,argument)*Q]` as signed i64 words, with `0 <= Q <= 64`.
Opcode `0` pushes an argument in `[-8,8]`. Opcode `1` pops and requires its
argument to be zero. A pop from an empty structure, unknown opcode, invalid
argument, or malformed frame returns `-1` without writing output. The maximum
valid input is 129 words; 130 words is the maximum parseable frame bound.

Each pop emits its removed value as a little-endian signed i64. The ABI return
value is the number of output bytes written: eight bytes per pop, up to 256
bytes. A null output pointer is accepted when the trace produces no pop results.
If one or more results are required, a null pointer or insufficient capacity
returns `-2` without writing.

## Methods and distinction

The primary ports keep one stack of push-event IDs per frequency, a frequency
table for the 17 supported values, and the current maximum frequency. This
uses linear time in the trace. The independent oracle stores the active push
sequence and rescans it at every pop to count values and select the rightmost
occurrence tied at the maximum. The bounded profile keeps that quadratic oracle
small.

The candidate was discovered from the public [LeetCode Stack topic index](https://leetcode.com/tag/stack/)
using title/topic metadata only. No individual problem page, problem text,
examples, tests, submissions, or site code were consulted. This online
frequency-priority removal differs from [`stack`](../../s/stack/README.md),
[`min_stack`](../../s/min_stack/README.md), and
[`stack_tracking_min_max`](../../s/stack_tracking_min_max/README.md), which
remove the most recently pushed item or track extrema. It also differs from
[`max_word`](../max_word/README.md), which counts a fixed input rather than
supporting online pushes and frequency-priority pops.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and the two
independent oracle modules at
[`benchmarks/maximum_frequency_stack_oracle.py`](../../maximum_frequency_stack_oracle.py)
and
[`benchmarks/maximum_frequency_stack_naive_oracle.py`](../../maximum_frequency_stack_naive_oracle.py).
The package-local static inventory checker is
[`verify_maximum_frequency_stack_package.py`](verify_maximum_frequency_stack_package.py).

## Language ports

| Language | Port |
| --- | --- |
| C | [`c/m/maximum_frequency_stack.c`](../../../c/m/maximum_frequency_stack.c) |
| C3 | [`c3/m/maximum_frequency_stack.c3`](../../../c3/m/maximum_frequency_stack.c3) |
| C++ | [`cpp/m/maximum_frequency_stack.cpp`](../../../cpp/m/maximum_frequency_stack.cpp) |
| Elisa | [`elisa/m/maximum_frequency_stack.elisa`](../../../elisa/m/maximum_frequency_stack.elisa) |
| Mojo | [`mojo/m/maximum_frequency_stack.mojo`](../../../mojo/m/maximum_frequency_stack.mojo) |
| Nim | [`nim/m/maximum_frequency_stack.nim`](../../../nim/m/maximum_frequency_stack.nim) |
| Odin | [`odin/m/maximum_frequency_stack.odin`](../../../odin/m/maximum_frequency_stack.odin) |
| Rust | [`rust/m/maximum_frequency_stack.rs`](../../../rust/m/maximum_frequency_stack.rs) |
| V | [`v/m/maximum_frequency_stack.v`](../../../v/m/maximum_frequency_stack.v) |
| Zig | [`zig/m/maximum_frequency_stack.zig`](../../../zig/m/maximum_frequency_stack.zig) |

All package work is source-only; no program, test, checker, build, compiler, or
benchmark has been run.
