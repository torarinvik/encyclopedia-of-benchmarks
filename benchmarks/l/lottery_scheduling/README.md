# Lottery scheduling

This benchmark runs the pinned Java `LotteryScheduling.scheduleProcesses` method with a fresh, explicitly seeded `java.util.Random`. The source's no-seed constructor is time-dependent and is outside the workload. The driver maps each input integer process ID to its decimal string for the source `Process` constructor and returns that ID with the source-computed timing fields.

## Contract

Input is a signed-i64 array `[seed, process_count, process_id, burst_time, tickets, ...]`. There are 0 to 16 processes. IDs are unique integers in `0..32767`, burst times and ticket counts are each in `1..1000`, and both the ticket total and total burst time are bounded by 16,000. This keeps the Java `int` accumulators from overflowing.

The schedule starts with current time zero. On each iteration it computes the remaining ticket total, calls `Random.nextInt(total_tickets) + 1`, and selects the first process whose cumulative tickets reach the winning ticket. It sets that process's waiting time to the current time, advances current time by its burst time, sets turnaround time to waiting time plus burst time, appends the process to the result, and removes that process before drawing again. The process list order breaks cumulative-ticket boundaries, and each selection removes a process before the next draw.

The workload uses `new Random(seed)` and reproduces Java's specified 48-bit linear-congruential state and bounded `nextInt` algorithm, including its power-of-two path and rejection condition. The input seed is signed i64; Java's `Random` initialization uses only the low 48 bits after scrambling. Each adapter call creates fresh process objects and RNG state.

Output is a little-endian signed-i64 sequence of triples `[process_id, waiting_time, turnaround_time]` in execution order. The maximum valid input is 50 words; 51 words are parseable for a trailing-data probe. The maximum output is 384 bytes. A valid empty schedule returns zero bytes when given a non-null output pointer and zero capacity.

Malformed framing, duplicate or out-of-range IDs, nonpositive or out-of-range burst times or ticket counts, or out-of-bound totals return `-1` before output checks. A null output pointer or insufficient capacity returns `-2` without writes, including for an empty schedule. A valid call returns the output byte length.

## Pinned source

- Java [`LotteryScheduling.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/LotteryScheduling.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.
- The [`Java SE Random specification`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/Random.html) fixes the seeded `Random` algorithms for portable Java behavior.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`lottery_scheduling_oracle.py`](../../lottery_scheduling_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/l/lottery_scheduling.c`](../../../c/l/lottery_scheduling.c) |
| C3 | [`c3/l/lottery_scheduling.c3`](../../../c3/l/lottery_scheduling.c3) |
| C++ | [`cpp/l/lottery_scheduling.cpp`](../../../cpp/l/lottery_scheduling.cpp) |
| Elisa | [`elisa/l/lottery_scheduling.elisa`](../../../elisa/l/lottery_scheduling.elisa) |
| Nim | [`nim/l/lottery_scheduling.nim`](../../../nim/l/lottery_scheduling.nim) |
| Odin | [`odin/l/lottery_scheduling.odin`](../../../odin/l/lottery_scheduling.odin) |
| Rust | [`rust/l/lottery_scheduling.rs`](../../../rust/l/lottery_scheduling.rs) |
| V | [`v/l/lottery_scheduling.v`](../../../v/l/lottery_scheduling.v) |
| Zig | [`zig/l/lottery_scheduling.zig`](../../../zig/l/lottery_scheduling.zig) |
