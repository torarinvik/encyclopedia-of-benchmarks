# Proportional fair scheduling

This benchmark ports the single-pass allocation method in the pinned Java [`ProportionalFairScheduling`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/ProportionalFairScheduling.java) source. It assigns a truncated weighted share of a fixed resource total to each process, in insertion order.

## Contract

The `i64_array_bytes_output` ABI accepts `[process_count, total_resources, name_id_0, weight_0, ...]`. There are 0–64 processes, total resources are 1–1,000,000, each weight is 1–1,000,000, and each name ID is a signed 32-bit integer. IDs are rendered as decimal process names by the source adapter; duplicate names are allowed. Input length must be exactly `2 + 2 * process_count`. The parser accepts at most 131 input values, which includes the maximum valid 130 values plus one trailing value for malformed-input coverage.

Each allocation follows the source expression in the same order: convert the process weight to binary64, divide by the integer total weight as binary64, multiply by total resources as binary64, then truncate toward zero as Java's `int` cast does. The weight sum is at most 64,000,000, so Java's 32-bit sum does not overflow. Nonempty inputs have positive total weight; the empty process list returns an empty result without dividing by zero. Zero and negative weights, zero or negative resource totals, and overflow-producing inputs are outside this bounded contract.

The output contains insertion-ordered `[name_id, allocation]` pairs as little-endian signed 64-bit integers. This numeric encoding preserves each source process identity, order, and allocation without depending on Java string formatting. A successful result is the output byte length, up to 1,024 bytes. Invalid input returns `-1`. A valid nonempty request with a null or short output buffer returns `-2` without writing. An empty request returns zero bytes, including when the output pointer is null.

[`workload.json`](workload.json) covers empty input, one process, fractional shares and leftover resources, duplicate names, equal weights, the maximum process count, invalid bounds and malformed lengths, and insufficient capacity. The independent oracle is [`benchmarks/proportional_fair_scheduling_oracle.py`](../../proportional_fair_scheduling_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/proportional_fair_scheduling.c](../../../c/p/proportional_fair_scheduling.c) |
| C3 | [c3/p/proportional_fair_scheduling.c3](../../../c3/p/proportional_fair_scheduling.c3) |
| C++ | [cpp/p/proportional_fair_scheduling.cpp](../../../cpp/p/proportional_fair_scheduling.cpp) |
| Elisa | [elisa/p/proportional_fair_scheduling.elisa](../../../elisa/p/proportional_fair_scheduling.elisa) |
| Nim | [nim/p/proportional_fair_scheduling.nim](../../../nim/p/proportional_fair_scheduling.nim) |
| Odin | [odin/p/proportional_fair_scheduling.odin](../../../odin/p/proportional_fair_scheduling.odin) |
| Rust | [rust/p/proportional_fair_scheduling.rs](../../../rust/p/proportional_fair_scheduling.rs) |
| V | [v/p/proportional_fair_scheduling.v](../../../v/p/proportional_fair_scheduling.v) |
| Zig | [zig/p/proportional_fair_scheduling.zig](../../../zig/p/proportional_fair_scheduling.zig) |

The source is distinct from the repository's `fair_share_scheduling` package: that benchmark aggregates task weights per user, sorts user IDs, and uses exact integer arithmetic. This benchmark handles each process independently, preserves insertion order, and follows Java's binary64 calculation.
