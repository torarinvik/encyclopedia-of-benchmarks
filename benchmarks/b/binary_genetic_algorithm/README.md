# Binary genetic algorithm

Minimize the number of set bits in a seeded population of binary candidates. This is a bounded deterministic adaptation of TheAlgorithms/MATLAB-Octave's `Run_GA` minimization example.

## Contract

- The `i64_array_scalar` input is `[seed, nVar, nPop, MaxIt]`. `seed` is 0 through `INT64_MAX`, `nVar` is 2–32, `nPop` is even and 2–16, and `MaxIt` is 1–32. The frame must contain exactly four signed 64-bit values.
- The objective is `sum(x*x)` for a binary vector, equal to its number of one bits. `beta=1`, crossover probability `pC=1`, and mutation probability `mu=0.02` are fixed. The result is the best cost found, from 0 through `nVar`; malformed or out-of-range input returns `-1`.
- The source's random-number generator is replaced by SplitMix64 so results are reproducible across ports. The state starts at `seed`; each word adds `0x9E3779B97F4A7C15` modulo 2^64, then applies xor-shift/multiply steps `(30, 0xBF58476D1CE4E5B9)`, `(27, 0x94D049BB133111EB)`, and a final xor-shift by 31. A unit draw is the high 53 bits divided by 2^53. For a bounded draw with bound `b`, reject words below `2^64 mod b` and return the accepted word modulo `b`; even a bound of one consumes a word.
- Initialization draws each candidate in population order, with genes ascending. Each mating pair selects parent one and then parent two by roulette; the first cumulative probability greater than or equal to `draw * sum(probabilities)` wins. Roulette weights are `exp(-cost / mean(cost))` when the mean cost is nonzero, otherwise `exp(-cost)`.
- Each pair chooses single-point, double-point, or uniform crossover with one bounded draw (`0`, `1`, `2` respectively). Single-point cuts after `1 + bounded(nVar-1)` genes. Double-point draws `a = 1 + bounded(nVar)`, then `b = 1 + bounded(nVar-1)` and increments `b` when `b >= a`, giving two distinct source cut counts; after sorting them as `lo < hi`, the zero-based half-open gene slice `[lo, hi)` comes from the other parent. Uniform crossover draws one bounded bit per gene; bit 1 selects parent one for the first child and bit 0 selects parent two. The second child uses the complementary parent choices.
- Mutation follows MATLAB column-major order for the offspring matrix: first children in pair order, then second children in pair order. Every gene consumes a unit draw and flips when it is below 0.02. Parents and offspring are merged and stably sorted by ascending cost; ties keep merged order. Best-ever cost updates only on strict improvement.
- A null input is invalid and returns `-1`. The workload admits one extra parseable value to exercise exact-frame rejection.

The pinned source's `Run_GA.m` and helper routines are at [TheAlgorithms/MATLAB-Octave commit `e150b77ad256de46c1ce3815c3d7945ac4fc28dc`](https://github.com/TheAlgorithms/MATLAB-Octave/tree/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function). Its `SinglePointCrossover.m`, `DoublePointCrossover.m`, `UniformCrossover.m`, `Mutate.m`, `RouletteWheelSelection.m`, and `SortPopulation.m` define the source operators.

`workload.json` covers minimum and maximum parameters, multi-generation evolution, the signed seed boundary, malformed frames, and invalid parameter bounds. `benchmarks/binary_genetic_algorithm_oracle.py` is the independent deterministic oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_genetic_algorithm.c`](../../../c/b/binary_genetic_algorithm.c) |
| C3 | [`c3/b/binary_genetic_algorithm.c3`](../../../c3/b/binary_genetic_algorithm.c3) |
| C++ | [`cpp/b/binary_genetic_algorithm.cpp`](../../../cpp/b/binary_genetic_algorithm.cpp) |
| Elisa | [`elisa/b/binary_genetic_algorithm.elisa`](../../../elisa/b/binary_genetic_algorithm.elisa) |
| Nim | [`nim/b/binary_genetic_algorithm.nim`](../../../nim/b/binary_genetic_algorithm.nim) |
| Odin | [`odin/b/binary_genetic_algorithm.odin`](../../../odin/b/binary_genetic_algorithm.odin) |
| Rust | [`rust/b/binary_genetic_algorithm.rs`](../../../rust/b/binary_genetic_algorithm.rs) |
| V | [`v/b/binary_genetic_algorithm.v`](../../../v/b/binary_genetic_algorithm.v) |
| Zig | [`zig/b/binary_genetic_algorithm.zig`](../../../zig/b/binary_genetic_algorithm.zig) |
