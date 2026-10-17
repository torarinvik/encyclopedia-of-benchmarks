# Minimizing Lateness

This package ports the pinned [TheAlgorithms/Java `MinimizingLateness`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/MinimizingLateness.java). It orders jobs by ascending deadline, starts each job when the previous job finishes, and reports nonnegative lateness. Equal deadlines retain input order, matching Java's stable object-array sort.

The `i64_array_bytes_output` input is `[n, processing_0, deadline_0, ..., processing_(n-1), deadline_(n-1)]`. There are 0 through 64 jobs. Processing times and deadlines are each in `[0, 2^31-1]`, and the sum of processing times must also be at most `2^31-1`, keeping completion times and lateness within int32.

Output is signed little-endian i32 `[n, (original_index, start_time, lateness)*]`, with records in stable deadline order. The maximum output is 772 bytes. Malformed input returns `-1`; a null output pointer or insufficient output capacity returns `-2`; both errors leave the output untouched. Even zero jobs require a non-null four-byte output for the count.

See [`workload.json`](workload.json) for stable-tie, zero-duration, late-job, maximum-bound, malformed-input, and capacity cases. The independent oracle is [`minimizing_lateness_oracle.py`](../../minimizing_lateness_oracle.py).

## Language ports

- C: [`c/m/minimizing_lateness.c`](../../../c/m/minimizing_lateness.c)
- C3: [`c3/m/minimizing_lateness.c3`](../../../c3/m/minimizing_lateness.c3)
- C++: [`cpp/m/minimizing_lateness.cpp`](../../../cpp/m/minimizing_lateness.cpp)
- Elisa: [`elisa/m/minimizing_lateness.elisa`](../../../elisa/m/minimizing_lateness.elisa)
- Nim: [`nim/m/minimizing_lateness.nim`](../../../nim/m/minimizing_lateness.nim)
- Odin: [`odin/m/minimizing_lateness.odin`](../../../odin/m/minimizing_lateness.odin)
- Rust: [`rust/m/minimizing_lateness.rs`](../../../rust/m/minimizing_lateness.rs)
- V: [`v/m/minimizing_lateness.v`](../../../v/m/minimizing_lateness.v)
- Zig: [`zig/m/minimizing_lateness.zig`](../../../zig/m/minimizing_lateness.zig)
