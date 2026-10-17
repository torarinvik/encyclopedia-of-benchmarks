# Sort population by cost

This benchmark ports the pinned MATLAB `SortPopulation(pop)` helper. It orders population records by ascending `Cost` and keeps each record's payload attached to its cost. Costs are distinct in the workload so MATLAB sort's tie ordering is not part of the contract.

## Contract

- ABI: `i64_array_bytes_output`. Input is `[n, cost_0, id_0, ..., cost_(n-1), id_(n-1)]`, with exact length `1 + 2*n` and `n` in `[1, 64]`.
- Costs are distinct signed integers in `[-1,000,000, 1,000,000]`. IDs are a permutation of `0..n-1`. These integer fields are exactly representable in the pinned MATLAB source's binary64 `Cost` values; the ID field stands in for the rest of a population record.
- Sort records by ascending cost and preserve each associated ID. Return the interleaved sorted `[cost, id]` records as little-endian signed 64-bit byte pairs, with no count prefix. Success returns the number of output bytes (`16*n`).
- Malformed framing, a cost outside the bound, duplicate costs, or IDs that are not a permutation of `0..n-1` return `-1`. For valid input, a null output pointer or capacity below `16*n` returns `-2` without writing.
- Maximum input length is 129 values; maximum output workspace is 1024 bytes. Empty populations are outside the benchmark's nonempty bounded domain.

The pinned helper computes `[~, so] = sort([pop.Cost])` and returns `pop(so)`. The benchmark models each source struct with its `Cost` and one ID payload, and excludes duplicate costs to avoid depending on tie behavior.

## Workload and oracle

[`workload.json`](workload.json) covers a single record, sorted and reverse-ordered records, negative/zero/positive and boundary costs, the 64-record maximum, malformed frames, duplicate costs, invalid IDs, and null/short output buffers. The independent [oracle](../../sort_population_oracle.py) sorts the validated `(cost, id)` pairs and serializes them.

## Pinned source

[TheAlgorithms/MATLAB-Octave `SortPopulation.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function/SortPopulation.m) sorts the population's `Cost` fields and indexes the full population with the returned order.

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm sort_population --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/sort_population/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm sort_population --languages rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/s/sort_population.c`](../../../c/s/sort_population.c) |
| C3 | [`c3/s/sort_population.c3`](../../../c3/s/sort_population.c3) |
| C++ | [`cpp/s/sort_population.cpp`](../../../cpp/s/sort_population.cpp) |
| Elisa | [`elisa/s/sort_population.elisa`](../../../elisa/s/sort_population.elisa) |
| Nim | [`nim/s/sort_population.nim`](../../../nim/s/sort_population.nim) |
| Odin | [`odin/s/sort_population.odin`](../../../odin/s/sort_population.odin) |
| Rust | [`rust/s/sort_population.rs`](../../../rust/s/sort_population.rs) |
| V | [`v/s/sort_population.v`](../../../v/s/sort_population.v) |
| Zig | [`zig/s/sort_population.zig`](../../../zig/s/sort_population.zig) |
