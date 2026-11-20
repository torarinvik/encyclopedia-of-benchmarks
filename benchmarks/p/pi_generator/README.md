# Pi digit spigot

This benchmark follows the pinned Python `calculate_pi(limit)` routine, which uses the `q, r, t, k, n, l` linear-fractional-transform recurrence from Jeremy Gibbons's unbounded spigot algorithm. Each step either emits a safe decimal digit or consumes another term of the series for π. The benchmark bounds the routine to eight fractional digits so its fixed-width integer ports stay within signed 64-bit arithmetic.

## Contract

- Input is a signed 64-bit count of fractional digits in `0..=8`.
- The source returns the ASCII decimal string `3.` followed by that many digits. The benchmark returns a 32-bit FNV-1a hash of the string to fit the scalar ABI.
- Inputs outside the range return `-1`.

The ports preserve the source's state updates and termination point. Precision is capped at eight fractional digits to keep intermediate integer values within the shared signed 64-bit range.

## Distinction from the bounded array spigot

[`spigotpi`](../../s/spigotpi/README.md) implements the Rabinowitz–Wagon mixed-radix array method: it initializes a finite array of remainders, sweeps from right to left, and carries each quotient into the preceding slot. This benchmark instead uses Gibbons's streaming recurrence over linear fractional transformations. Both emit decimal digits incrementally, but their state, recurrence, and underlying computation differ; they remain separate algorithm benchmarks.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/pi_generator.c`](../../../c/p/pi_generator.c) |
| C3 | [`c3/p/pi_generator.c3`](../../../c3/p/pi_generator.c3) |
| C++ | [`cpp/p/pi_generator.cpp`](../../../cpp/p/pi_generator.cpp) |
| Elisa | [`elisa/p/pi_generator.elisa`](../../../elisa/p/pi_generator.elisa) |
| Nim | [`nim/p/pi_generator.nim`](../../../nim/p/pi_generator.nim) |
| Odin | [`odin/p/pi_generator.odin`](../../../odin/p/pi_generator.odin) |
| Rust | [`rust/p/pi_generator.rs`](../../../rust/p/pi_generator.rs) |
| V | [`v/p/pi_generator.v`](../../../v/p/pi_generator.v) |
| Zig | [`zig/p/pi_generator.zig`](../../../zig/p/pi_generator.zig) |

## Workload and recording

[`workload.json`](workload.json) covers zero through eight fractional digits and invalid bounds. The source-backed runtime oracle is [`pi_generator_oracle.py`](../../pi_generator_oracle.py). Build with the scalar ABI and record using `benchmarks/run_scalar.py`.

## Pinned source

- [TheAlgorithms/Python `pi_generator.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/pi_generator.py)
- Jeremy Gibbons, [“Unbounded Spigot Algorithms for the Digits of Pi”](https://www.cs.ox.ac.uk/people/jeremy.gibbons/publications/spigot.pdf), especially the streaming recurrence for π.
