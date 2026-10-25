# Richards packet-task scheduler

This package independently ports the pinned Richards systems-programming
benchmark. It models the six priority-linked task control blocks, the source
state-bit transitions, and the packet flow between worker, handler, and device
tasks. This event-driven cooperative scheduler is distinct from process
schedulers that choose jobs by arrival, burst, priority, time slice, or ticket
count.

## Contract

- ABI: `i64_array_scalar`, symbol `richards_benchmark`.
- Input is `[idle_count]`, with `1 <= idle_count <= 1,000,000`. The upper bound
  is the pinned source's `SMALL_PROBLEM_SIZE` iteration count.
- The six tasks retain source priorities, list insertion order, packet queue
  ordering, state-bit transitions, strict priority preemption on an empty
  queue, and worker/device/handler callbacks. The initial two work packets and
  six device packets are reused through the bounded scheduler.
- The result is `qpkt_count * 2^31 + hold_count`, preserving both source
  counters, which use signed `int` fields. The source's small-problem profile
  gives 2,326,389 queue packets and 930,555 holds.
- Invalid array length or iteration bounds return `-1`.

The independent [Python oracle](../../richards_benchmark_oracle.py) represents
packet links with integer indices and simulates the scheduler transitions.
The workload includes the pinned small profile and invalid framing/bounds.

## Provenance and license

The pinned launcher builds `richards_benchmark.c` with `-lm` and supplies no
runtime arguments. Neither the source file nor the package launcher contains a
license declaration; this package does not infer an upstream license. The
language ports and oracle are independent implementations and do not copy the
upstream source text.

- [Pinned C source](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/richards_benchmark/richards_benchmark.c)
- [Pinned launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/richards_benchmark/info.sh)

## Language ports

| Language | Source |
| --- | --- |
| C | [c/r/richards_benchmark.c](../../../c/r/richards_benchmark.c) |
| C3 | [c3/r/richards_benchmark.c3](../../../c3/r/richards_benchmark.c3) |
| C++ | [cpp/r/richards_benchmark.cpp](../../../cpp/r/richards_benchmark.cpp) |
| Elisa | [elisa/r/richards_benchmark.elisa](../../../elisa/r/richards_benchmark.elisa) |
| Nim | [nim/r/richards_benchmark.nim](../../../nim/r/richards_benchmark.nim) |
| Odin | [odin/r/richards_benchmark.odin](../../../odin/r/richards_benchmark.odin) |
| Rust | [rust/r/richards_benchmark.rs](../../../rust/r/richards_benchmark.rs) |
| V | [v/r/richards_benchmark.v](../../../v/r/richards_benchmark.v) |
| Zig | [zig/r/richards_benchmark.zig](../../../zig/r/richards_benchmark.zig) |
