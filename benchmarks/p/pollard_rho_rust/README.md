# Pollard's Rho (Rust source variant)

Return one factor using the pinned Rust implementation's seeded LCG and Brent cycle search.

## Contract

- The `i64_array_scalar` ABI accepts `[number, seed, restart_limit]` with exactly three signed 64-bit integers. The parser accepts at most four values so trailing input can be rejected.
- Valid inputs use `2 <= number <= 1000000000`, `0 <= seed <= 4294967295`, and `1 <= restart_limit <= 16`. The number bound stays within the pinned source's deterministic Miller–Rabin range for its selected bases.
- Enable the source's primality check. If its Miller–Rabin routine reports probable prime, return `number` without advancing the seed. Otherwise reproduce the source LCG (`1103515245`, `12345`, wrapping u32 state) and its draws of `x` and `c`; map them to `x0 = x % (number-3) + 2` and `c = c % (number-2) + 1`.
- Run the pinned Brent routine with batch size 32 and iteration cutoff `1 << 18`. A proper factor is returned. The source retries when the result is `1` or `number`; the bounded adapter allows at most `restart_limit` such attempts and returns `0` if none yields a proper factor.
- Malformed framing or out-of-domain values return `-1`.

The restart limit bounds the source's retry loop. The output preserves its prime behavior (`number`) and its first proper factor. See the [workload](workload.json) and [oracle](../../pollard_rho_rust_oracle.py).

## Pinned source

[`pollard_rho.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/pollard_rho.rs) at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`.

## Implementations

| Language | Port |
|---|---|
| C | [pollard_rho_rust.c](../../../c/p/pollard_rho_rust.c) |
| C3 | [pollard_rho_rust.c3](../../../c3/p/pollard_rho_rust.c3) |
| C++ | [pollard_rho_rust.cpp](../../../cpp/p/pollard_rho_rust.cpp) |
| Elisa | [pollard_rho_rust.elisa](../../../elisa/p/pollard_rho_rust.elisa) |
| Nim | [pollard_rho_rust.nim](../../../nim/p/pollard_rho_rust.nim) |
| Odin | [pollard_rho_rust.odin](../../../odin/p/pollard_rho_rust.odin) |
| Rust | [pollard_rho_rust.rs](../../../rust/p/pollard_rho_rust.rs) |
| V | [pollard_rho_rust.v](../../../v/p/pollard_rho_rust.v) |
| Zig | [pollard_rho_rust.zig](../../../zig/p/pollard_rho_rust.zig) |
