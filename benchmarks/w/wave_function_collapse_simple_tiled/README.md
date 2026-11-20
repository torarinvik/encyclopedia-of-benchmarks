# Simple-Tiled Wave Function Collapse

This profile models a small grid of tile domains and directional adjacency constraints. It uses minimum-domain observation, a caller-supplied weighted draw for each cell, and FIFO support propagation. The profile is deterministic for a fixed input and deliberately does not backtrack after a contradiction.

## Contract

- ABI: `i64_array_scalar`. Input is a signed 64-bit array `[width,height,k,domains[cells],weights[k],adjacency[4*k],draws[cells]]`.
- `1 <= width,height <= 4`, `cells = width*height <= 16`, and `1 <= k <= 4`. Each row-major domain is a nonempty mask of the `k` tile IDs. Weights are integers in `1..4`. Draws are integers in `0..65535`.
- Adjacency rows are stored direction-major in `north,east,south,west` order; each row mask lists the tile IDs permitted in the neighboring cell. North/south and east/west relations must be reciprocal. The grid has no wraparound, and edges at the grid boundary impose no constraint.
- The exact valid input length is `3 + 2*cells + 5*k`, at most 55 values. Length 56 is the largest parseable malformed frame. Null, malformed, out-of-range, and nonreciprocal inputs return `-1`.
- Before observation, enqueue every cell once in row-major order. Propagation uses FIFO order and an in-queue flag: clear the flag when a cell is popped, and append each changed neighbor only if it is not already queued. When a cell is popped, inspect its neighbors in north/east/south/west order and remove each neighbor tile that has no support in the popped cell's current domain.
- Repeatedly choose a nonsingleton cell with the fewest remaining tiles; ties go to the first row-major cell. For that cell, calculate `rank = floor(draw * sum(candidate_weights) / 65536)`, scan candidate tile IDs ascending, and subtract each tile's weight until the selected interval contains the rank. Set the domain to that singleton and propagate from it with the same FIFO and deduplication rules.
- If propagation empties a domain, return `-2`. Do not try another tile. Otherwise return a signed 64-bit integer with bit 32 set and each row-major tile ID encoded in two bits beginning at bit `2*cell_index`.

## Method and bounds

Wave Function Collapse is presented as a constraint-solving content-generation method by Karth and Smith. This bounded profile isolates simple-tiled adjacency, weighted observation, and propagation. Initialization reaches arc consistency for the supplied domains before any weighted choice; later choices propagate only their support reductions. The packed bit masks, FIFO queue, row-major tie rule, and draw values make behavior reproducible across ports.

For `C = width*height` and `k` tile types, reciprocal validation takes `O(k^2)`. Each domain can lose candidates at most `k` times and a queued cell examines at most four neighbors, with support construction bounded by `O(k)`; propagation therefore takes `O(C*k^2)` over the run. MRV scans at most `C` cells for each of at most `C` observations, for `O(C^2)` total. Workspace is bounded by 1,024 bytes, including fixed domain, weight, adjacency, draw, queue, and in-queue arrays.

## Sources

- Karth and Smith, [“WaveFunctionCollapse is constraint solving in the wild”](https://doi.org/10.1145/3102071.3110566), FDG 2017.
- Karth and Smith, [“WaveFunctionCollapse: Content Generation via Constraint Solving and Machine Learning”](https://doi.org/10.1109/TG.2021.3076368).
- Discovery only: the [pinned RosettaCodeData popular-task title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks). No task page or solution was consulted.

## Package files

- [`workload.json`](workload.json): bounded contract and static fixtures.
- [`primary_oracle.py`](primary_oracle.py): bitmask FIFO reference.
- [`independent_oracle.py`](independent_oracle.py): set-domain reference using ordered full arc-consistency sweeps.
- [`verify_workload.py`](verify_workload.py): source-level workload/reference reconciler; it is provided but has not been run.
- [`check_inventory.py`](check_inventory.py): source and artifact inventory checker; it is provided but has not been run.
- [`INVENTORY.json`](INVENTORY.json): machine-readable artifact and native source list.
- [`RIGHTS.md`](RIGHTS.md): provenance and clean-room implementation note.

## Native ports

| Language | Source |
|---|---|
| C | `c/w/wave_function_collapse_simple_tiled.c` |
| C3 | `c3/w/wave_function_collapse_simple_tiled.c3` |
| C++ | `cpp/w/wave_function_collapse_simple_tiled.cpp` |
| Elisa | `elisa/w/wave_function_collapse_simple_tiled.elisa` |
| Mojo | `mojo/w/wave_function_collapse_simple_tiled.mojo` |
| Nim | `nim/w/wave_function_collapse_simple_tiled.nim` |
| Odin | `odin/w/wave_function_collapse_simple_tiled.odin` |
| Rust | `rust/w/wave_function_collapse_simple_tiled.rs` |
| V | `v/w/wave_function_collapse_simple_tiled.v` |
| Zig | `zig/w/wave_function_collapse_simple_tiled.zig` |
