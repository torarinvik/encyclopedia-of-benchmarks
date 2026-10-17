# Slack Time Scheduling

Sort tasks by increasing slack, where slack is deadline minus execution time, and return their input order.

## Contract

- ABI: i64_array_bytes_output.
- Input is [n, execution_0, deadline_0, ...], with exact length 1 + 2*n and 0 <= n <= 64.
- Each execution time and deadline is an integer from 0 through 1,000,000. This keeps Java's signed-int slack calculation within range.
- Compute deadline - execution for each task and sort by increasing slack. The sort is stable, so tasks with equal slack retain input order. The source returns task names; the adapter identifies tasks by their zero-based input indices.
- Output the sorted task indices as little-endian signed i64 values, with no count prefix (8*n bytes, maximum 512).
- Null input, malformed framing, or out-of-range values return -1 before output storage is checked. Null output or insufficient capacity returns -2 without writes. A nonnull zero-capacity output succeeds for an empty task list.

The benchmark preserves the source's stable sort result and does not simulate task execution or completion.

## Workload

The [workload](workload.json) covers empty and singleton inputs, negative slack, ordinary ordering, stable equal-slack ties, duplicate tasks as distinct input indices, maximum task count, malformed input, null input/output, capacity boundaries, and invalid-input precedence. The [oracle](../../slack_time_scheduling_oracle.py) independently sorts task indices by their slack values.

## Implementations

| Language | Source |
| --- | --- |
| C | [C source](../../../c/s/slack_time_scheduling.c) |
| C3 | [C3 source](../../../c3/s/slack_time_scheduling.c3) |
| C++ | [C++ source](../../../cpp/s/slack_time_scheduling.cpp) |
| Elisa | [Elisa source](../../../elisa/s/slack_time_scheduling.elisa) |
| Nim | [Nim source](../../../nim/s/slack_time_scheduling.nim) |
| Odin | [Odin source](../../../odin/s/slack_time_scheduling.odin) |
| Rust | [Rust source](../../../rust/s/slack_time_scheduling.rs) |
| V | [V source](../../../v/s/slack_time_scheduling.v) |
| Zig | [Zig source](../../../zig/s/slack_time_scheduling.zig) |

## Pinned source

[TheAlgorithms/Java SlackTimeScheduling.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/SlackTimeScheduling.java) at commit e43ec3897e48f23843972d02cd05a5bb1b6864a2. Its comparator uses only deadline minus execution time, and Java list sorting preserves task order for equal keys.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm slack_time_scheduling --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm slack_time_scheduling
```
