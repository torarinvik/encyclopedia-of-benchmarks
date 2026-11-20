# Brownian-tree diffusion-limited aggregation

This package measures a deterministic, bounded lattice version of diffusion-limited aggregation (DLA). It keeps the characteristic process: particles make random walks and stick at the first empty site adjacent to the growing cluster. Randomness is replayable from a supplied seed, and each particle has a fixed walk budget.

## Contract

- ABI: `i64_array_bytes_output`, symbol `brownian_tree_diffusion_limited_aggregation`.
- A valid input is exactly `[attempts, seed, step_cap]`; `0 <= attempts <= 16`, `1 <= seed <= INT64_MAX`, and `1 <= step_cap <= 512`. The workload allows a four-word malformed buffer to cover trailing-data rejection; any length other than three returns `-1`.
- The grid has coordinates `0..32` on each axis. The initial cluster contains `(16,16)`. Each attempt uses its own PRNG stream. Its initial state is `seed XOR (0x9e3779b97f4a7c15 * (attempt+1))` modulo 2^64; replace a zero state with `0x2545f4914f6cdd1d`.
- A random draw updates xorshift64 state with `x ^= x >> 12`, `x ^= x << 25`, and `x ^= x >> 27`, masking to 64 bits after each step. The returned word is the updated state multiplied modulo 2^64 by `0x2545f4914f6cdd1d`. Map a draw to `[0,bound)` by its unsigned remainder.
- Launch draws choose side `draw % 4`, then position `1 + draw % 31`. Side order is top `(position,1)`, right `(31,position)`, bottom `(position,31)`, left `(1,position)`. The launch site is inside the outer ring and uses its own numbered attempt stream.
- If the launch site is already occupied, discard that attempt after consuming its side and position draws. Otherwise, check its four neighbors immediately and attach there if it already touches the cluster. Direction draws map `0=left`, `1=up`, `2=right`, `3=down`. After each move, discard the particle if it reaches the outer ring `x=0`, `x=32`, `y=0`, or `y=32`; otherwise, attach the current empty site at its first orthogonal contact. Neighbor checks use left, up, right, down order. If it does not attach within `step_cap` moves, discard it.
- Output is `[point_count,x0,y0,...]` as little-endian signed-i64 words. The center seed is first, followed by attached sites in insertion order. `point_count` includes the seed. The maximum output is 35 words (280 bytes). Null output or insufficient capacity returns `-2` and writes nothing.

The profile processes at most 16 particle attempts and 512 moves per attempt. The largest fixed native scratch is 1,361 bytes: a 33×33 occupancy bitmap plus two 17-entry 64-bit coordinate arrays in the C3 port. The declared workspace ceiling is 2,048 bytes, excluding caller-owned buffers.

The short-walk fixtures cap attempts at 13 moves. Every launch begins at Manhattan distance at least 15 from the center, so reaching a site adjacent to the initial cluster requires at least 14 moves. Those fixtures therefore have the known one-point output even with multiple attempts. A zero-attempt fixture separately covers the maximum step-cap boundary.

## References and provenance

The [RosettaGit Brownian tree task](https://rosettagit.org/tasks/brownian-tree/) supplied the broad seed, moving-particle, collision, and attachment idea. The algorithm semantics come from Witten and Sander's DLA model: particles start far from a seed, walk randomly, join on reaching a site adjacent to the cluster, and are removed if they touch the lattice boundary. See [“Diffusion-Limited Aggregation, a Kinetic Critical Phenomenon,” *Physical Review Letters* 47 (1981)](https://acoustique.ec-lyon.fr/chaos/WittenSander_PhysRevLett81.pdf), p. 1400.

The local search found no Brownian-tree or DLA package. [`monte_carlo_simulation`](../../m/monte_carlo_simulation/README.md) and HJM paths model geometric Brownian motion in financial calculations; they do not grow an aggregate by random walkers sticking to a cluster. The PRNG, grid, launch ring, output framing, fixtures, and language implementations here are original. No task text, code, tests, or sample outputs were copied.

The primary reference simulates attempts online with a bitmap. The independent reference precomputes each attempt's path, then processes those paths against a list of occupied sites. [`verify_workload.py`](verify_workload.py) compares pinned fixture results and bytes against both references without loading native ports. See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and [`INVENTORY.md`](INVENTORY.md).
