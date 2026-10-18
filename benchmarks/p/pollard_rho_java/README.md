# Pollard's Rho (Java source variant)

Return the first gcd produced by the pinned Java Floyd-cycle Pollard's rho implementation.

## Contract

- The `i64_array_scalar` ABI accepts `[n, step_limit]` with exactly two signed 64-bit integers. The parser accepts at most three values so trailing input can be rejected.
- Valid inputs use `2 <= n <= 46340` and `1 <= step_limit <= 4096`. The modulus bound keeps the pinned Java `int` square-and-subtract expression in range.
- Start `x = y = 2`, set `d = 1`, and for each allowed step update `x = g(x)`, then `y = g(g(y))`, then `d = gcd(abs(x-y), n)`, where `g(v) = ((v*v)-1) % n` uses Java's signed remainder (a negative numerator can produce `-1`).
- Return `d` when `1 < d < n`. Map the source exception on `d == n` to `0`. If the wrapper's step limit expires while `d == 1`, return `-2`. Malformed framing or out-of-domain values return `-1`.

The step limit is a bounded-adapter guard; within it, the update order and Java remainder behavior follow the pinned source exactly. See the [workload](workload.json) and [oracle](../../pollard_rho_java_oracle.py).

## Pinned source

[`PollardRho.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PollardRho.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Implementations

| Language | Port |
|---|---|
| C | [pollard_rho_java.c](../../../c/p/pollard_rho_java.c) |
| C3 | [pollard_rho_java.c3](../../../c3/p/pollard_rho_java.c3) |
| C++ | [pollard_rho_java.cpp](../../../cpp/p/pollard_rho_java.cpp) |
| Elisa | [pollard_rho_java.elisa](../../../elisa/p/pollard_rho_java.elisa) |
| Nim | [pollard_rho_java.nim](../../../nim/p/pollard_rho_java.nim) |
| Odin | [pollard_rho_java.odin](../../../odin/p/pollard_rho_java.odin) |
| Rust | [pollard_rho_java.rs](../../../rust/p/pollard_rho_java.rs) |
| V | [pollard_rho_java.v](../../../v/p/pollard_rho_java.v) |
| Zig | [pollard_rho_java.zig](../../../zig/p/pollard_rho_java.zig) |
