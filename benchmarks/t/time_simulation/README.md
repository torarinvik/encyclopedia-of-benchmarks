# Time simulation

This benchmark follows the pinned Zig [`Clock`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/tiger_style/time_simulation.zig), a bounded virtual clock with schedule, cancel, tick, time, and empty-query operations. The benchmark starts a fresh clock at time zero for every call.

## Contract

The `i64_array_scalar` input is `[action_count, (opcode, operand)*]`, with no separate length prefix. Require `0 <= action_count <= 4096` and exactly `1 + 2*action_count` signed 64-bit words. The parser admits one trailing word, up to 8194 values, so malformed extra fields can be rejected.

| Opcode | Operation | Operand |
|---:|---|---|
| 0 | Schedule an event at an absolute timestamp | Timestamp in `0..=2^63-1` |
| 1 | Cancel an event | Nonzero event ID in `1..=2^32-1` |
| 2 | Tick to an inclusive target time | Timestamp in `0..=2^63-1` |
| 3 | Read the current time | Must be zero |
| 4 | Check whether the queue is empty | Must be zero |

The clock begins at time zero. A scheduled timestamp must be at least the current time, and tick targets must not move backward. These timestamps are a bounded subset of the source's `u64` domain; limiting them to signed-i64 maximum also guarantees that the source's `target + 1` scan bound cannot overflow. Invalid arity, opcode, operand, schedule-in-the-past, or backward tick returns `-1`.

Scheduling selects the first inactive slot and assigns sequential nonzero `u32` IDs. The queue holds at most 1024 active events; scheduling while full returns ID zero without changing the ID counter. Cancellation returns one if an active event was cancelled and zero for an unknown or already inactive nonzero ID. ID zero is invalid because the source asserts that cancellation IDs are nonzero. A tick processes every event with timestamp at most the target. It repeatedly selects the earliest timestamp and resolves ties by the first active slot in ascending slot order. Each event is made inactive before its fixed callback records `(event_id, event_timestamp)` in fire order; the callback does not reschedule. The clock then advances to the requested target. Although only 1024 events can be active at once, up to 4092 can fire over a 4096-action trace; the callback log is bounded for that cumulative count.

For each action, the trace records its return value: scheduled ID, cancellation flag, processed count, current time, or empty flag. The output is the low 63 bits of FNV-1a-64 over these unsigned 64-bit words in order:

`[action_count, action_results..., fired_count, (fired_id, fired_timestamp)*, final_now, final_active_event_count, total_events_processed]`

Hash each word's eight little-endian bytes in order, starting from `14695981039346656037` and multiplying by `1099511628211` after each XOR, modulo `2^64`. The output is the resulting hash masked with `0x7FFFFFFFFFFFFFFF`. The oracle is [`time_simulation_oracle.py`](../../time_simulation_oracle.py).

## Workload and build

[`workload.json`](workload.json) covers inclusive firing, cancellation, event ordering after slot reuse, time/empty queries, high bounded timestamps, malformed actions, the full 1024-slot queue plus one overflow schedule attempt, and the maximum cumulative firing count across repeated batches.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm time_simulation --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/t/time_simulation/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms time_simulation --languages rust
```

## Pinned source

- [Zig `tiger_style/time_simulation.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/tiger_style/time_simulation.zig)

