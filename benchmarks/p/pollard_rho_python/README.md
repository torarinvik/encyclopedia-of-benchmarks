# Pollard's Rho (Python source variant)

Return the nontrivial divisor found by the pinned Python Floyd-cycle implementation.

## Contract

- The `i64_array_scalar` ABI accepts `[num, seed, step, attempts, step_limit]` with exactly five signed 64-bit integers. The parser accepts at most six values so trailing input can be rejected.
- Valid inputs use `2 <= num <= 1000000`, `0 <= seed < num`, `0 <= step <= 1000`, `1 <= attempts <= 8`, and `1 <= step_limit <= 64`.
- For `num > 2` even, return `2` immediately. Otherwise each attempt starts `tortoise = hare = seed` and advances with `f(x) = (x*x + step) mod num`. Each iteration updates the tortoise once and the hare twice, then computes `gcd(hare-tortoise, num)`. A proper gcd is returned; a gcd equal to `num` ends that attempt.
- After a failed attempt, set `seed = hare` and increment `step`, as the source does. The bounded adapter ends an attempt after `step_limit` iterations. Return `0` when all attempts fail or reach their step caps. Malformed framing or out-of-domain values return `-1`.

The step cap makes the source's unbounded per-attempt loop finite for benchmark calls. See the [workload](workload.json) and [oracle](../../pollard_rho_python_oracle.py).

## Pinned source

[`pollard_rho.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/pollard_rho.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Implementations

| Language | Port |
|---|---|
| C | [pollard_rho_python.c](../../../c/p/pollard_rho_python.c) |
| C3 | [pollard_rho_python.c3](../../../c3/p/pollard_rho_python.c3) |
| C++ | [pollard_rho_python.cpp](../../../cpp/p/pollard_rho_python.cpp) |
| Elisa | [pollard_rho_python.elisa](../../../elisa/p/pollard_rho_python.elisa) |
| Nim | [pollard_rho_python.nim](../../../nim/p/pollard_rho_python.nim) |
| Odin | [pollard_rho_python.odin](../../../odin/p/pollard_rho_python.odin) |
| Rust | [pollard_rho_python.rs](../../../rust/p/pollard_rho_python.rs) |
| V | [pollard_rho_python.v](../../../v/p/pollard_rho_python.v) |
| Zig | [pollard_rho_python.zig](../../../zig/p/pollard_rho_python.zig) |
