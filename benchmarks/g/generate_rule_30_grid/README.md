# Generate a Rule 30 grid

This benchmark covers the pinned Python `generate_rule_30(size, generations)` wrapper. It returns the seeded initial row and then synchronously evolves each following row with Rule 30. It is distinct from [`elementary`](../elementary/README.md), which benchmarks one generation from a caller-provided row.

## Contract

Input is exactly `[width, generation_count]`, with each value from 1 through 64. The pinned wrapper indexes the first row and seed cell, so zero width or zero generations raises an indexing error; malformed or out-of-range inputs return `-1` in the portable contract.

The result is `width * generation_count` output bytes, flattened row-major in generation order. The first row is zero-filled except for a live cell at index `width // 2` (the right-of-center cell for even widths). The requested count includes this seeded row; each later row applies one synchronous Rule 30 transition. Cells beyond either finite row edge are dead. A too-small output buffer returns `-2` without writing. The maximum output is 4,096 bytes.

The independent oracle is [`benchmarks/generate_rule_30_grid_oracle.py`](../../generate_rule_30_grid_oracle.py). The workload includes seed-only, width-one/even-width behavior, multi-step evolution, capacity failure, malformed dimensions, and the maximum grid.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm generate_rule_30_grid --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/g/generate_rule_30_grid/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm generate_rule_30_grid
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/g/generate_rule_30_grid.c`](../../../c/g/generate_rule_30_grid.c) |
| C3 | [`c3/g/generate_rule_30_grid.c3`](../../../c3/g/generate_rule_30_grid.c3) |
| C++ | [`cpp/g/generate_rule_30_grid.cpp`](../../../cpp/g/generate_rule_30_grid.cpp) |
| Elisa | [`elisa/g/generate_rule_30_grid.elisa`](../../../elisa/g/generate_rule_30_grid.elisa) |
| Nim | [`nim/g/generate_rule_30_grid.nim`](../../../nim/g/generate_rule_30_grid.nim) |
| Odin | [`odin/g/generate_rule_30_grid.odin`](../../../odin/g/generate_rule_30_grid.odin) |
| Rust | [`rust/g/generate_rule_30_grid.rs`](../../../rust/g/generate_rule_30_grid.rs) |
| V | [`v/g/generate_rule_30_grid.v`](../../../v/g/generate_rule_30_grid.v) |
| Zig | [`zig/g/generate_rule_30_grid.zig`](../../../zig/g/generate_rule_30_grid.zig) |

## TheAlgorithms reference

- [Python `elementary_cellular_automaton.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/cellular_automata/elementary_cellular_automaton.py)
