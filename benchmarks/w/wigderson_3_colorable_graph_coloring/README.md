# Wigderson 3-colorable graph coloring

This bounded profile implements Wigderson's Algorithm A for a promised
3-colorable simple graph. It is distinct from ordinary greedy coloring,
Welsh–Powell, DSatur, backtracking, and Pannotia priority-extrema coloring.
Those profiles do not repeatedly color a maximum-degree vertex's induced
neighborhood as a bipartite graph and remove its closed neighborhood.

## Contract

- Exported symbol: `wigderson_3_colorable_graph_coloring`; ABI:
  `i64_array_bytes_output`.
- Input is `[n,m,u0,v0,...,u(m-1),v(m-1)]`, with `0<=n<=32` and
  `0<=m<=128`. Every edge is a simple undirected edge listed exactly once as
  `u<v`. Malformed lengths, loops, duplicates, reversed pairs, out-of-range
  endpoints, and a selected neighborhood that is not bipartite return `-1`.
- The method's input promise is that the graph is 3-colorable. The ports check
  each neighborhood bipartition they need; they do not solve the 3-colorability
  decision problem. A rejected non-bipartite neighborhood is outside the
  promised domain.
- Let `n` be the original vertex count and `i=1`. While the current maximum
  degree is at least `floor(sqrt(n))`, select a maximum-degree current vertex,
  breaking ties by smallest vertex ID. Two-color its induced current
  neighborhood with labels `i` and `i+1`; assign `i+2` to the selected vertex;
  remove that vertex and all its current neighbors; then advance `i` by two,
  exactly as Algorithm A prints. The prior center's label may be reused by the
  next neighborhood pair because the center and its entire neighborhood were
  removed. The original `n` fixes the threshold throughout the run.
- Each neighborhood component starts at its smallest vertex ID and is
  two-colored by BFS, scanning neighbors in ascending ID. In the residual
  graph, visit vertices in ascending ID and assign the smallest available
  color ID at least `i` (sequential first-fit).
- Output bytes are `[highest_color_id, color(0), ..., color(n-1)]`; IDs are
  one-based, and an empty graph emits the single byte `0`. The first byte is
  the highest assigned label tracked by the source's color counter; it can
  include an unused label when a neighborhood component uses only one side.
- The largest valid frame is 258 i64 words; 259 words are parseable so a
  trailing-word error remains bounded. The maximum output is 33 bytes. A
  malformed or out-of-promise input returns `-1`; a null or undersized output
  buffer returns `-2` and remains untouched. Successful return is the number
  of bytes written.
- The fixed graph and traversal tables use at most 2,048 bytes across the
  native representations; this excludes input, output, and call-stack space.

## Method and references

The primary reference runs Algorithm A directly over an active-vertex graph
with an adjacency-list BFS for each neighborhood. The independent reference
uses adjacency bitsets, recomputed induced degrees, and stack-based component
propagation. Both orient each bipartite component from its smallest vertex ID,
so their normalized byte outputs agree while their graph representations and
traversals differ.

Wigderson proves that Algorithm A colors every 3-colorable `n`-vertex graph
with at most `3 floor(sqrt(n))` color labels. The profile measures the
deterministic bounded trace and does not claim an approximation guarantee for
graphs outside the promise.

Primary source: Wigderson, [“Improving the Performance Guarantee for
Approximate Graph Coloring”](https://doi.org/10.1145/2157.2158), JACM 30(4),
729–735 (1983), §2, Algorithm A and Theorem 2.1. Chapter context:
*Encyclopedia of Algorithms*, Chapter 170, [“Graph
Coloring”](https://doi.org/10.1007/978-1-4939-2864-4_170). See
[`RIGHTS.md`](RIGHTS.md).

## Files

- [`primary_oracle.py`](primary_oracle.py): active-graph/BFS reference.
- [`independent_oracle.py`](independent_oracle.py): bitset/stack reference and
  proper-coloring validator.
- [`workload.json`](workload.json): bounded ABI and golden fixtures.
- [`INVENTORY.md`](INVENTORY.md), [`inventory.json`](inventory.json): static
  ten-language source inventory.
- [`check_inventory.py`](check_inventory.py): static metadata reviewer; it has
  not been run.

Elisa validates the pointer-bearing C ABI boundary, then processes its input
view and writes through a bounded output view. C++ independently implements
the same bounded state machine with `std::array` and standard algorithms.
