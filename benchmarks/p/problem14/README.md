# Project Euler Problem 14

## Contract

Return the starting value in `1..=limit` with the longest Collatz chain, where
`limit` is in `1..=1,000,000`. The chain length counts both the starting value
and the terminal `1`. Invalid limits return `-1`.

If several starts tie, the contract returns the smallest. The pinned Go source
iterates a map when selecting a maximum, so ties can otherwise depend on map
iteration order. Its package-level cache can also retain values across calls;
the ports define each call from the requested limit alone. These choices make
the bounded benchmark result deterministic while preserving the canonical
Problem 14 answer.

The ports evaluate the Collatz recurrence with 64-bit unsigned intermediates.
They reject a trajectory if it overflows or exceeds 10,000 terms; every start
in the supported limit range terminates well below that guard.

## Workload

[`workload.json`](workload.json) covers the base cases, a short range, the
canonical one-million limit, and invalid bounds. The canonical case uses one
repetition per sample because it evaluates one million starting values.

## TheAlgorithms reference

- Go [`Problem14`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_14/problem14.go) computes Collatz chain weights for a caller-provided inclusive limit.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem14.c](../../../c/p/problem14.c) |
| C3 | [c3/p/problem14.c3](../../../c3/p/problem14.c3) |
| C++ | [cpp/p/problem14.cpp](../../../cpp/p/problem14.cpp) |
| Elisa | [elisa/p/problem14.elisa](../../../elisa/p/problem14.elisa) |
| Nim | [nim/p/problem14.nim](../../../nim/p/problem14.nim) |
| Odin | [odin/p/problem14.odin](../../../odin/p/problem14.odin) |
| Rust | [rust/p/problem14.rs](../../../rust/p/problem14.rs) |
| V | [v/p/problem14.v](../../../v/p/problem14.v) |
| Zig | [zig/p/problem14.zig](../../../zig/p/problem14.zig) |
