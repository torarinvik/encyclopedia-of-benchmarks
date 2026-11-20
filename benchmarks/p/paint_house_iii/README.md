# Paint House III

This package implements a bounded, clean-room version of the Paint House III
optimization problem. The input is `[m,n,target,houses...,costs...]`. There are
`m` houses and `n` colors; house value zero means unpainted, while values 1..n
are fixed colors. The `m*n` painting costs follow in house-major, color-minor
order. A neighborhood is a maximal contiguous run of one color.

The result is the minimum cost of assigning colors to all unpainted houses so
the completed row has exactly `target` neighborhoods. Fixed houses incur no
cost. A valid instance with no qualifying assignment and any malformed or
out-of-profile frame both return `-1`, following this repository's scalar
sentinel convention.

The profile bounds `m` to 1..8, `n` to 1..4, `target` to 1..m, and costs to
0..100. The exact input length is `3 + m + m*n`, at most 43 words. The parser
accepts at most 44 words so a maximum-size frame with one trailing word is
covered as malformed. The largest valid cost is 800.

The primary method keeps the best cost by house index, last color, and current
neighborhood count. It rolls two `[color][neighborhood]` layers and considers
every previous color. Its time is `O(m*n^2*target)` and auxiliary space is
`O(n*target)`. The independent reference enumerates every color assignment to
the unpainted houses and directly counts the resulting runs; it does not use
the DP recurrence.

This is distinct from the local graph-coloring, tree-edge-painting,
linear-partition, divide-and-conquer partition, and job-scheduling packages:
those do not minimize repainting costs for a fixed linear row with an exact
number of color runs. Discovery and high-level method hints came from the
[official LeetCode 1473 page](https://leetcode.com/problems/paint-house-iii/);
the implementation and bounded workload are original.

## Package files

- `primary_oracle.py` — bounded rolling DP reference.
- `independent_oracle.py` — exhaustive assignment reference.
- `workload.json` — hand-derived fixtures, including both frame bounds.
- `verify_workload.py` — fixture agreement checker (not run for this draft).
- `check_inventory.py` — static-only artifact and port inventory.
- `RIGHTS.md` — provenance and clean-room notes.
- `INVENTORY.md` — the ten exported source paths.

## Language ports

- `c/p/paint_house_iii.c`
- `c3/p/paint_house_iii.c3`
- `cpp/p/paint_house_iii.cpp`
- `elisa/p/paint_house_iii.elisa`
- `mojo/p/paint_house_iii.mojo`
- `nim/p/paint_house_iii.nim`
- `odin/p/paint_house_iii.odin`
- `rust/p/paint_house_iii.rs`
- `v/p/paint_house_iii.v`
- `zig/p/paint_house_iii.zig`
