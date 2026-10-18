# Python travelling salesman genetic algorithm

This package preserves the pinned genetic-algorithm `main` method on a bounded two-city domain. Input is `[population_size, iterations, crossover_probability, mutation_probability, x0, y0, x1, y1]`. The two source dictionary keys are inserted as `0` then `1`; the coordinates are distinct integer points in `[-16,16]`. Population size is an even integer from 2 through 8, iterations are 0 through 12, and probabilities are in `[0,1]`.

No random seed or replacement RNG is introduced. On this domain, `init` can only sample the single non-origin city, so every chromosome is `[0,1,0]`. Roulette selection chooses only identical chromosomes, crossover exchanges identical genes, and mutation swaps the sole interior position with itself. Thus every possible global-RNG draw leaves the returned route and distance unchanged, while the source's initialization, fitness, selection, crossover, and mutation loops still execute. Coincident coordinates are excluded because fitness divides by a zero route length.

Output is `[path_length, city_indices..., total_distance]`, specifically route `[0,1,0]` and twice the Euclidean distance between the two points. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes. Comparisons use absolute and relative tolerance `1e-12`. See the [workload](workload.json), [oracle](../../travelling_salesman_python_genetic_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/genetic_algorithm/travelling_salesman_problem.py).

## Ports

- [C](../../../c/t/travelling_salesman_python_genetic.c)
- [C++](../../../cpp/t/travelling_salesman_python_genetic.cpp)
- [C3](../../../c3/t/travelling_salesman_python_genetic.c3)
- [Rust](../../../rust/t/travelling_salesman_python_genetic.rs)
- [Elisa](../../../elisa/t/travelling_salesman_python_genetic.elisa)
- [Nim](../../../nim/t/travelling_salesman_python_genetic.nim)
- [Odin](../../../odin/t/travelling_salesman_python_genetic.odin)
- [V](../../../v/t/travelling_salesman_python_genetic.v)
- [Zig](../../../zig/t/travelling_salesman_python_genetic.zig)
