# Random Scheduling

This benchmark measures the pinned Java scheduler's seeded random permutation of a task collection. Task identifiers stand in for task names; the scheduler only copies and reorders the collection, so identifier values do not affect the random stream.

## Contract

Input is a signed-i64 array:

```text
[seed, task_count, task_0, ..., task_(task_count-1)]
```

`seed` is any signed 64-bit integer. `task_count` is 0 through 32. Task identifiers are signed 32-bit integers; duplicates are allowed and retain their multiplicity. Input length must equal `task_count + 2`.

Each call constructs the same random stream as Java `new Random(seed)`. Its 48-bit state starts at `(seed XOR 0x5DEECE66D) AND (2^48 - 1)`, then advances with `state = (state * 0x5DEECE66D + 0xB) AND (2^48 - 1)`. `nextInt(bound)` uses Java's power-of-two fast path and signed-overflow rejection rule for other bounds. The source copies the task collection, then shuffles that copy using the backward Fisher–Yates loop: for `i` from `task_count` down to 2, swap positions `i-1` and `nextInt(i)`. A zero- or one-item list consumes no random values. This exact random stream and shuffle sequence are normative benchmark behavior for reproducibility; the benchmark does not claim that `Collections.shuffle` guarantees an identical permutation across all JDK implementations.

Output is the shuffled task IDs as little-endian signed-i64 words. The maximum valid input length is 34 words; 35 words are parseable for a trailing-data probe. Output and workspace are bounded at 256 bytes. A valid call returns the number of output bytes; an empty task list succeeds with zero bytes when given a non-null output pointer. Null input, malformed framing, count, or task IDs returns `-1` before output checks. A null output pointer or insufficient capacity returns `-2` after input validation. Errors write no bytes.

## Pinned source

- Java [`RandomScheduling.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/RandomScheduling.java), class `RandomScheduling`, commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/random_scheduling_oracle.py`](../../random_scheduling_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/r/random_scheduling.c`](../../../c/r/random_scheduling.c) |
| C3 | [`c3/r/random_scheduling.c3`](../../../c3/r/random_scheduling.c3) |
| C++ | [`cpp/r/random_scheduling.cpp`](../../../cpp/r/random_scheduling.cpp) |
| Elisa | [`elisa/r/random_scheduling.elisa`](../../../elisa/r/random_scheduling.elisa) |
| Nim | [`nim/r/random_scheduling.nim`](../../../nim/r/random_scheduling.nim) |
| Odin | [`odin/r/random_scheduling.odin`](../../../odin/r/random_scheduling.odin) |
| Rust | [`rust/r/random_scheduling.rs`](../../../rust/r/random_scheduling.rs) |
| V | [`v/r/random_scheduling.v`](../../../v/r/random_scheduling.v) |
| Zig | [`zig/r/random_scheduling.zig`](../../../zig/r/random_scheduling.zig) |
