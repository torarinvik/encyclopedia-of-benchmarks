# Wa-Tor

This benchmark adapts the pinned [TheAlgorithms/Python `cellular_automata/wa_tor.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/cellular_automata/wa_tor.py), which simulates prey and predator entities on a finite grid.

## Contract

- The input is `[width, height, chronons, kind, reproduction_timer, energy, ...]`, followed by one cell triplet per cell in row-major order. Width and height are each `1..8`; chronons are `0..32`; the exact length is `3 + 3 * width * height`.
- A cell triplet is `(0, 0, 0)` for empty, `(1, timer, 0)` for prey with timer `0..5`, or `(2, timer, energy)` for a predator with timer `0..20` and energy `0..15`. The initial grid is the deterministic equivalent of calling `set_planet` with entities whose state is explicitly supplied; it avoids the source constructor's random population placement.
- Each chronon snapshots current entity IDs in row-major order. Each entity in that snapshot acts once, dead entities are skipped, and offspring wait until the next chronon. The source's random entity ordering and direction/target shuffles are replaced by fixed choices: prey and predator movement use N,E,S,W; predator prey-target selection uses the source helper's N,S,W,E neighbor order. This is a deterministic normalization of the source's stochastic `run()` loop.
- The board is finite with no wraparound, matching the source's in-bounds neighbor checks. A moving entity takes the first empty neighbor in its movement order. If it moved and its timer is zero or lower, it reproduces in its previous cell and resets its timer to 5 for prey or 20 for predators; otherwise its timer decreases by one, including when movement is blocked.
- A predator with zero energy at the start of its turn is removed. Otherwise it eats the first adjacent prey in N,S,W,E order when one exists, gains 5 energy, and then loses one energy. Eating does not change its reproduction timer. Without adjacent prey it follows the movement/reproduction rule and then loses one energy.
- Source constants are preserved: prey reproduction time 5, predator reproduction time 20, initial predator energy 15, food value 5, and the source's entity limits. On this at-most-64-cell board, the 450-entity balance purge and 500-entity cap cannot be reached.
- The output is a deterministic row-major state fingerprint plus population counts. Cell codes are folded as `hash = (hash * 1,000,003 + code) mod 2,147,483,647`, where empty is `0`, prey is `timer + 33`, and predator is `1,000 + 53 * energy + timer + 32`. The result is `hash * 4,225 + 65 * prey_count + predator_count`. Invalid shapes, cell states, or bounds return `-1`.

The independent oracle is [`benchmarks/wa_tor_oracle.py`](../../wa_tor_oracle.py). The workload covers movement priority, edge behavior, blocked countdowns, reproduction, predation, starvation, snapshot ordering, multi-chronon state changes, and invalid inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/wa_tor.c`](../../../c/w/wa_tor.c) |
| C3 | [`c3/w/wa_tor.c3`](../../../c3/w/wa_tor.c3) |
| C++ | [`cpp/w/wa_tor.cpp`](../../../cpp/w/wa_tor.cpp) |
| Elisa | [`elisa/w/wa_tor.elisa`](../../../elisa/w/wa_tor.elisa) |
| Nim | [`nim/w/wa_tor.nim`](../../../nim/w/wa_tor.nim) |
| Odin | [`odin/w/wa_tor.odin`](../../../odin/w/wa_tor.odin) |
| Rust | [`rust/w/wa_tor.rs`](../../../rust/w/wa_tor.rs) |
| V | [`v/w/wa_tor.v`](../../../v/w/wa_tor.v) |
| Zig | [`zig/w/wa_tor.zig`](../../../zig/w/wa_tor.zig) |
