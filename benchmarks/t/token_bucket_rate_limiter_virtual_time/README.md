# Token bucket rate limiter with virtual time

This benchmark replays request admissions against a token bucket. Each request
supplies an integer interval since the previous request; the benchmark refills
the bucket, caps it at capacity, then admits the request if a token is
available and consumes one token. The bucket starts full.

## Contract

The `i64_array_scalar` entry point is
`token_bucket_rate_limiter_virtual_time`. Input is
`[capacity, refill_rate, request_count, elapsed_ticks...]`, with capacity in
`0..=64`, refill rate in `0..=32`, request count in `0..=63`, and each elapsed
interval in `0..=256`. The exact input length is `3 + request_count`, at most
66 signed 64-bit words.

Elapsed values are whole virtual ticks since the prior request, with the first
interval measured since bucket creation. Before each request, the implementation
adds `elapsed_ticks * refill_rate`, capped at capacity. A request succeeds and
consumes one token exactly when the resulting balance is positive. The result
is a bit mask: bit `i` is set when request `i` is allowed. With no requests the
result is zero. Invalid input returns `-1`.

The bounds keep refill products within signed 64-bit arithmetic. The primary
reference applies refill with one multiplication per request; the independent
reference adds tokens one virtual tick at a time. The workload covers full
capacity, depletion, refill after empty, saturation, zero-capacity buckets,
maximum interval, maximum request count/result, and malformed frames.

This is distinct from a wall-clock rate-limiter implementation: there are no
clock reads, sleeps, or concurrent calls. It is also distinct from fixed-window
and leaky-bucket policies because it stores a capped token balance and adds
tokens at a configured rate.

## Source and rights

Algorithm source: [TheAlgorithms/Java `TokenBucket.java`](https://github.com/TheAlgorithms/Java/blob/master/src/main/java/com/thealgorithms/datastructures/queues/TokenBucket.java).
The source repository is MIT-licensed; only the refill and admission idea was
used. See [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/t/token_bucket_rate_limiter_virtual_time.c`](../../../c/t/token_bucket_rate_limiter_virtual_time.c) |
| C3 | [`c3/t/token_bucket_rate_limiter_virtual_time.c3`](../../../c3/t/token_bucket_rate_limiter_virtual_time.c3) |
| C++ | [`cpp/t/token_bucket_rate_limiter_virtual_time.cpp`](../../../cpp/t/token_bucket_rate_limiter_virtual_time.cpp) |
| Elisa | [`elisa/t/token_bucket_rate_limiter_virtual_time.elisa`](../../../elisa/t/token_bucket_rate_limiter_virtual_time.elisa) |
| Mojo | [`mojo/t/token_bucket_rate_limiter_virtual_time.mojo`](../../../mojo/t/token_bucket_rate_limiter_virtual_time.mojo) |
| Nim | [`nim/t/token_bucket_rate_limiter_virtual_time.nim`](../../../nim/t/token_bucket_rate_limiter_virtual_time.nim) |
| Odin | [`odin/t/token_bucket_rate_limiter_virtual_time.odin`](../../../odin/t/token_bucket_rate_limiter_virtual_time.odin) |
| Rust | [`rust/t/token_bucket_rate_limiter_virtual_time.rs`](../../../rust/t/token_bucket_rate_limiter_virtual_time.rs) |
| V | [`v/t/token_bucket_rate_limiter_virtual_time.v`](../../../v/t/token_bucket_rate_limiter_virtual_time.v) |
| Zig | [`zig/t/token_bucket_rate_limiter_virtual_time.zig`](../../../zig/t/token_bucket_rate_limiter_virtual_time.zig) |

The package-local [`verify_workload.py`](verify_workload.py) statically checks
fixture metadata and language-port inventory. Shared suite and catalog
integration remain separate.
