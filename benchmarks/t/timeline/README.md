# Timeline

This package benchmarks a bounded command trace over the pinned C# `Timeline<TValue>` collection, instantiated with `TValue = long`. It preserves the source's stable chronological sort in the event-array constructor, insertion-order queries, and append-only behavior of later `Add` calls. Although the source describes the collection as sorted, `Add` does not re-sort it.

## Contract

Input is a signed-i64 array:

```text
[initial_count, time_0, value_0, ..., command_count,
 command_0, arg_0, arg_1, ...]
```

The `initial_count` event pairs use the source's array constructor, which stable-sorts by `DateTime` ticks. Each command is exactly three words `[opcode, first, second]`. Supported opcodes are:

| Opcode | Operation | Arguments | Result record payload |
|---:|---|---|---|
| 0 | `Add(time, value)` | tick time, value | empty |
| 1 | `Contains(time, value)` | tick time, value | one boolean word |
| 2 | `Remove(time, value)` | tick time, value | one boolean word; removes the first match |
| 3 | `GetValuesByTime(time)` | tick time, second word 0 | matching values in current event order |
| 4 | `GetTimesBefore(time)` | tick time, second word 0 | distinct earlier times in ascending order |
| 5 | `GetTimesAfter(time)` | tick time, second word 0 | distinct later times in ascending order |
| 6 | `RemoveTimes(time)` | tick time, second word 0 | one boolean word; removes every event at that time |
| 7 | `RemoveValues(value)` | value, second word 0 | one boolean word; removes every event with that value |
| 8 | `ContainsTime(time)` | tick time, second word 0 | one boolean word |
| 9 | `ContainsValue(value)` | value, second word 0 | one boolean word |
| 10 | `GetAllTimes()` | both words 0 | distinct times in first-seen order |
| 11 | `GetAllValues()` | both words 0 | values in current event order |
| 12 | `TimesCount` | both words 0 | one count word |
| 13 | `ValuesCount` / `Count` | both words 0 | one count word |
| 14 | `Clear()` | both words 0 | empty |

Times are `DateTime(ticks)` values in `0..1,000,000`; values are signed integers in `[-32,32]`. These ranges keep the source's calendar-component queries out of scope while retaining the exact `DateTime` comparison and equality behavior used by the operations above. `AddNow`, calendar-component filters, `ToDictionary`, and timeline equality are excluded. The adapter validates the entire command stream before applying it.

For every command the output contains `[opcode, payload_count, payload...]`. After the command records it contains `[-1, final_event_count, time_0, value_0, ...]` in the timeline's current list order. All output words are signed 64-bit little-endian values. The maximum valid input is 130 words; 131 words are parseable for the trailing-data probe. The maximum output is 5,528 bytes, reached by 16 initial events, 9 appends, and 23 full-value queries.

Malformed framing, out-of-range values, unknown commands, or nonzero unused operands return `-1` before output checks. A null output pointer or insufficient capacity returns `-2` without writes. A valid call returns the number of output bytes.

## Pinned source

- C# [`Timeline.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Timeline.cs), class `Timeline<TValue>` at commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`timeline_oracle.py`](../../timeline_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/t/timeline.c`](../../../c/t/timeline.c) |
| C3 | [`c3/t/timeline.c3`](../../../c3/t/timeline.c3) |
| C++ | [`cpp/t/timeline.cpp`](../../../cpp/t/timeline.cpp) |
| Elisa | [`elisa/t/timeline.elisa`](../../../elisa/t/timeline.elisa) |
| Nim | [`nim/t/timeline.nim`](../../../nim/t/timeline.nim) |
| Odin | [`odin/t/timeline.odin`](../../../odin/t/timeline.odin) |
| Rust | [`rust/t/timeline.rs`](../../../rust/t/timeline.rs) |
| V | [`v/t/timeline.v`](../../../v/t/timeline.v) |
| Zig | [`zig/t/timeline.zig`](../../../zig/t/timeline.zig) |
