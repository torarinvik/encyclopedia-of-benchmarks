# Jenkins One-at-a-Time hash

This benchmark ports the pinned Python Jenkins One-at-a-Time hash. It consumes each input byte in order, mixing and masking to 32 bits after every source operation.

## Contract

The `i64_array_scalar` input is `[n, byte...]`, with `n` from 0 through 64 and exactly `n` following ASCII byte values from 0 through 127. This bounded ASCII domain is a subset of Python strings after UTF-8 encoding. The result is an unsigned 32-bit hash represented as an integer in `[0, 2^32-1]`; malformed inputs return `-1`. Embedded zero bytes are valid data because this Python implementation iterates over the entire encoded string.

The [workload](workload.json) includes the pinned examples, byte boundaries, empty input, maximum length, and malformed layouts. The independent oracle is [`jenkins_one_at_a_time_oracle.py`](../../jenkins_one_at_a_time_oracle.py).

The benchmark is distinct from DJB2 and SDBM: it applies per-byte add/shift/xor mixing with 32-bit wrapping.
