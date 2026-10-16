# Project Euler Problem 123: Prime square remainders

## Contract

The pinned source starts with `n=1` and the first prime. It checks `2 × p_n × n > limit`; on failure it consumes the next prime without checking it, increments `n` by 2, and continues. Thus it tests odd indices in order and returns the first index whose source remainder exceeds the threshold. The comparison is strict, so equality does not stop the search.

The benchmark supports integer thresholds up to 10,000,000,000. Negative thresholds are accepted and return 1, as does zero. Values above 10,000,000,000 return -1. The source examples return 2,371 at 100,000,000 and 7,037 at 1,000,000,000; its default threshold returns 21,035.

The ports use an ordinary sieve to generate the same prime sequence and preserve the source's skipped-even-index / first-hit order. The sieve bound is sufficient for the supported threshold range.

## Workload

The [workload JSON](workload.json) covers the initial threshold boundaries, strict-equality cases, source examples and default, and an out-of-domain value.

## TheAlgorithms reference

- Python [sol1.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_123/sol1.py) searches odd prime indices using the simplified remainder condition.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem123.c](../../../c/p/problem123.c) |
| C3 | [c3/p/problem123.c3](../../../c3/p/problem123.c3) |
| C++ | [cpp/p/problem123.cpp](../../../cpp/p/problem123.cpp) |
| Elisa | [elisa/p/problem123.elisa](../../../elisa/p/problem123.elisa) |
| Nim | [nim/p/problem123.nim](../../../nim/p/problem123.nim) |
| Odin | [odin/p/problem123.odin](../../../odin/p/problem123.odin) |
| Rust | [rust/p/problem123.rs](../../../rust/p/problem123.rs) |
| V | [v/p/problem123.v](../../../v/p/problem123.v) |
| Zig | [zig/p/problem123.zig](../../../zig/p/problem123.zig) |
