# Left-right planar embedding

This profile recognizes a bounded simple undirected graph with the left-right
planarity method and emits a cyclic neighbor order for each vertex when a
planar embedding exists. The local [`rotation_system_planarity_test`](../rotation_system_planarity_test/README.md)
searches all cyclic orders for graphs of at most six vertices and returns only a
Boolean. This profile instead uses DFS lowpoints and conflict-pair constraints,
then constructs an embedding witness. The distinction is the planarity method
and the returned certificate, not just the spelling of the task.

## Contract

- Exported symbol: `planar_embedding_lr`; ABI: `i64_array_bytes_output`.
- Input: `[N, M, u0, v0, ..., u(M-1), v(M-1)]`, with `1<=N<=32` and
  `0<=M<=96`.
- The graph is simple and undirected. Every edge is listed once as `u<v` with
  both endpoints in `0..N-1`. Loops, repeated edges, reversed pairs, malformed
  lengths, and out-of-range values return `-1`.
- Output byte `0` is status. `0` means nonplanar and is the complete output.
  `1` means planar and is followed by one byte for every adjacency, grouped by
  vertex ID; each group gives that vertex's neighbors in cyclic order. Input
  degrees determine group boundaries. Isolated vertices contribute no bytes.
- The largest parseable input has 195 i64 words. The largest valid input has
  194 words. The declared output-buffer bound is 193 bytes (the planar simple
  graph edge bound makes the largest realizable witness 181 bytes). A valid
  call with a null or too small output buffer returns `-2` without writing
  output. Successful return
  values are the number of bytes written; workload `expected_result` fields pin
  that count (one byte for a nonplanar status, otherwise `1 + 2*M`).
- The fixed graph, conflict-stack, ordering, and rotation tables use at most
  50,208 bytes across the ten native representations (the Elisa/Nim/Odin
  i64-sized tables are the largest: 49,440 bytes for `State` plus 768 bytes
  for the 96-element depth array). Side resolution has at most 96 recursive
  edge frames; graph DFS and embedding depth are at most 32. This table
  accounting excludes the host call stack.
- Roots and adjacency rows are processed in ascending vertex ID. Equal nesting
  depths are ordered by destination ID, so all ports choose the same output.

## Method and references

The primary uses fixed-array state and recursive DFS steps with depth at most
32: orient edges, compute lowpoint pairs and nesting order, process return-edge
constraints with a conflict-pair stack, resolve relative sides, and assemble
the rotation system by inserting return edges around reference darts. The LR
passes are linear. Dense endpoint, adjacency, outgoing-order, and rotation
tables add `O(N²)` setup and workspace; deterministic insertion sorting adds
`Σ_v degree(v)²` work.

For small graphs (`N<=6`), the independent decision reference enumerates
rotation systems and checks face walks by Euler's formula. The certificate
validator works through `N<=32`: it checks every adjacency appears exactly
once, traces directed face walks, and checks `V-E+F=2` separately for each
nontrivial connected component. The workload's nonplanar cases stay within the
small exhaustive decision bound; larger fixtures are planar and checked by
their embedding certificate.

The algorithm follows Brandes, [“The Left-Right Planarity Test”](https://www.uni-konstanz.de/algo/publications/b-lrpt-sub.pdf).
The NetworkX 3.7 [planarity implementation](https://github.com/networkx/networkx/blob/networkx-3.7/networkx/algorithms/planarity.py)
was consulted as a secondary description of the same method. The code was
written independently and does not reproduce that implementation.
The [Library Checker planar-embedding proposal #1426](https://github.com/yosupo06/library-checker-problems/pull/1426)
is used to discover the task and its witness shape. It specifies disconnected
simple graphs and cyclic neighbor order output. No Library Checker code,
problem text, or fixtures are reused. See [`RIGHTS.md`](RIGHTS.md).

## Files

- [`primary_oracle.py`](primary_oracle.py): left-right method reference.
- [`independent_oracle.py`](independent_oracle.py): bounded exhaustive decision
  reference and independent rotation-certificate validator.
- [`workload.json`](workload.json): limits and workload profiles.
- [`INVENTORY.md`](INVENTORY.md) and [`inventory.json`](inventory.json): static
  language-port inventory.
- [`check_inventory.py`](check_inventory.py): package-local static inventory
  reviewer. It has not been run.

The ten source paths are listed in the inventory. Elisa stores graph state in
bounded local arrays and views after its ABI boundary checks. C++ has its own
fixed-array implementation using `std::array`; it does not include the C kernel.

The ABI returns bytes rather than text: this keeps the ten native ports on a
fixed, allocation-bounded output path and preserves the witness without locale
or formatting differences.
