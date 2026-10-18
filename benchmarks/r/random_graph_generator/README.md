# Deterministic random graph generation

This benchmark covers the pinned Python `random_graph` edge-generation operation. It replaces the process-global random stream with explicit per-pair draws so each source decision is reproducible; graph representation and edge order remain source-compatible.

## Contract

Input is `[n, directed, probability_units, draw_0, ...]`. The vertex count `n` is 0 through 64, `directed` is exactly 0 or 1, and `probability_units` is an integer in `[-2^53, 2^54]`. It represents `probability = probability_units / 2^53`, so this domain covers probabilities from -1 through 2 on the source random stream's 53-bit grid.

For `probability_units <= 0`, the source returns an empty adjacency list without drawing random values. For `probability_units >= 2^53`, it returns a complete undirected graph, even when `directed` is 1. For intermediate probabilities, supply one draw numerator in `[0,2^53)` for every unordered pair `(i,j)` in nested order `i=0..n-1`, `j=i+1..n-1`. Each numerator represents `random.random() = draw / 2^53`; the source adds the edge exactly when `draw < probability_units`. Directed mode adds only `i -> j`; undirected mode also adds `j -> i`. Endpoint branches consume no draws. The input length is exactly 3 plus the number of required draws, with a maximum valid length of 2,019 words and a maximum parseable length of 2,020 words for an extra-word probe.

Output is an `n × n` row-major byte adjacency matrix. Every byte is 0 or 1; the diagonal is always zero. This preserves the source graph's adjacency and neighbor order, because the source appends each vertex's neighbors in ascending vertex order. The maximum output is 4,096 bytes, and a valid call returns the byte length. For `n=0`, a nonnull zero-capacity output succeeds with result 0; a null output returns `-2` even for that empty result.

Malformed framing, unsupported values, or an out-of-range draw returns `-1` before output checks. A null output pointer or insufficient capacity returns `-2` after input validation. Errors write no output bytes.

The independent oracle is [`../../random_graph_generator_oracle.py`](../../random_graph_generator_oracle.py). The workload covers empty and endpoint-probability graphs, strict threshold behavior, both directed modes, the source's `p >= 1` undirected-complete quirk, maximum output, malformed framing, and output-capacity edges.

## Pinned source

- Python [`random_graph_generator.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/random_graph_generator.py), specifically `random_graph(vertices_number, probability, directed)`. The separate `complete_graph` helper is exercised through the `probability >= 1` branch.

## Language ports

| Language | Port |
|---|---|
| C | [`c/r/random_graph_generator.c`](../../../c/r/random_graph_generator.c) |
| C3 | [`c3/r/random_graph_generator.c3`](../../../c3/r/random_graph_generator.c3) |
| C++ | [`cpp/r/random_graph_generator.cpp`](../../../cpp/r/random_graph_generator.cpp) |
| Elisa | [`elisa/r/random_graph_generator.elisa`](../../../elisa/r/random_graph_generator.elisa) |
| Nim | [`nim/r/random_graph_generator.nim`](../../../nim/r/random_graph_generator.nim) |
| Odin | [`odin/r/random_graph_generator.odin`](../../../odin/r/random_graph_generator.odin) |
| Rust | [`rust/r/random_graph_generator.rs`](../../../rust/r/random_graph_generator.rs) |
| V | [`v/r/random_graph_generator.v`](../../../v/r/random_graph_generator.v) |
| Zig | [`zig/r/random_graph_generator.zig`](../../../zig/r/random_graph_generator.zig) |
