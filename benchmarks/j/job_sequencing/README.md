# Job sequencing

This benchmark follows the pinned Java and Rust greedy job-sequencing routines. Jobs are considered in descending profit order and assigned to the latest free time slot at or before their deadline. The Java method expects that order from its caller; Rust sorts internally. The benchmark restricts profits to a strictly descending input sequence, so both implementations process the same order without profit ties.

## Contract

Input is a signed 64-bit array `[job_count, id_byte, deadline, profit, ...]`. Job count is 1 through 32. IDs are unique ASCII letters (`A-Z` or `a-z`), deadlines are 1 through `job_count`, and profits are 1 through 1,000,000 and strictly descending in input order. The packed input length is exactly `1 + 3 * job_count`. Each job takes one unit of time. Process each job in input order and place it in the latest unoccupied slot no later than its deadline; skip it if no slot is free.

Output bytes are `[scheduled_count:u8, total_profit:u64 little-endian, scheduled IDs in increasing slot order]`. Empty slots are omitted, matching the sequence returned by both source algorithms. The Java display prefix and arrow separators are presentation formatting and are excluded. Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writing. Maximum output capacity is 41 bytes.

The [independent oracle](../../job_sequencing_oracle.py) and [`workload.json`](workload.json) include the pinned examples, same-deadline contention, gaps, bounds, malformed records, and output-capacity cases.

## Pinned sources

- [TheAlgorithms/Java `JobSequencing.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/JobSequencing.java)
- [TheAlgorithms/Rust `job_sequencing.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/greedy/job_sequencing.rs)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/j/job_sequencing.c`](../../../c/j/job_sequencing.c) |
| C3 | [`c3/j/job_sequencing.c3`](../../../c3/j/job_sequencing.c3) |
| C++ | [`cpp/j/job_sequencing.cpp`](../../../cpp/j/job_sequencing.cpp) |
| Elisa | [`elisa/j/job_sequencing.elisa`](../../../elisa/j/job_sequencing.elisa) |
| Nim | [`nim/j/job_sequencing.nim`](../../../nim/j/job_sequencing.nim) |
| Odin | [`odin/j/job_sequencing.odin`](../../../odin/j/job_sequencing.odin) |
| Rust | [`rust/j/job_sequencing.rs`](../../../rust/j/job_sequencing.rs) |
| V | [`v/j/job_sequencing.v`](../../../v/j/job_sequencing.v) |
| Zig | [`zig/j/job_sequencing.zig`](../../../zig/j/job_sequencing.zig) |
