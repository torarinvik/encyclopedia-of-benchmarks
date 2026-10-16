# String genetic algorithm

Evolve a fixed-size population of candidate strings until one exactly matches a target. Fitness counts matching characters at the same positions. Each generation ranks candidates, preserves the highest-scoring third, selects parents, crosses them at one split point, and mutates genes with probability 2/5.

## Contract

- Input is `[target_length, gene_count, seed, max_generations, target_bytes..., gene_bytes...]` using signed 64-bit values. Targets contain 1–8 printable ASCII characters; the alphabet contains 1–32 printable ASCII genes and must include every target character. Seeds are 1 through 2,147,483,646; generation bounds are 1 through 1,000.
- The population has 200 individuals. Parent selection draws from the 51 highest-ranked members, uses the 50 ranked parents in order, and creates up to 10 child pairs per parent in proportion to fitness. Ties retain population order. The 66 highest-scoring individuals survive into the next generation.
- A Park–Miller generator with multiplier 48,271 and modulus 2,147,483,647 drives initial genes, parent choice, crossover, and mutation. Bounded values use the next state modulo the bound; mutation occurs when a draw modulo 5 is 0 or 1.
- On success, the function returns 16 and writes `[generation_found, total_population_evaluated]` as two little-endian signed 64-bit values. If no exact match is found by the generation limit, it returns `-1` without output. Malformed input or insufficient output capacity returns `-2` without output.
- Implementations use fixed-size arrays and portable integer arithmetic; they require no architecture-specific instructions or floating-point fitness calculations.

## Source normalization

The pinned Python routine uses an unseeded random source and has no generation limit, so its result and runtime are not reproducible. It also keeps the first 66 previous candidates rather than the 66 highest-scoring ones. This contract supplies an explicit seed and bound, keeps a fixed-size population, and preserves the highest-scoring candidates so every language runs the same bounded evolution.

## Workload and verification

[`workload.json`](workload.json) includes one- and multi-generation convergence, a bounded non-converging case, invalid parameters, and insufficient output capacity. Verify with `python3 benchmarks/verify_string_genetic_algorithm.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.

## Pinned source

- TheAlgorithms/Python [`basic_string.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/genetic_algorithm/basic_string.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/string_genetic_algorithm.c`](../../../c/s/string_genetic_algorithm.c) |
| C3 | [`c3/s/string_genetic_algorithm.c3`](../../../c3/s/string_genetic_algorithm.c3) |
| C++ | [`cpp/s/string_genetic_algorithm.cpp`](../../../cpp/s/string_genetic_algorithm.cpp) |
| Elisa | [`elisa/s/string_genetic_algorithm.elisa`](../../../elisa/s/string_genetic_algorithm.elisa) |
| Nim | [`nim/s/string_genetic_algorithm.nim`](../../../nim/s/string_genetic_algorithm.nim) |
| Odin | [`odin/s/string_genetic_algorithm.odin`](../../../odin/s/string_genetic_algorithm.odin) |
| Rust | [`rust/s/string_genetic_algorithm.rs`](../../../rust/s/string_genetic_algorithm.rs) |
| V | [`v/s/string_genetic_algorithm.v`](../../../v/s/string_genetic_algorithm.v) |
| Zig | [`zig/s/string_genetic_algorithm.zig`](../../../zig/s/string_genetic_algorithm.zig) |
