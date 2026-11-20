# Random permutation count with a cycle-length cap

Count the permutations of `n` labels in which every cycle has length at most
`k`. In the cycle-following strategy for the locker puzzle, this is the exact
number of arrangements in which all participants find their labels within
`k` openings. Divide the returned count by `n!` to obtain the success
probability under a uniformly random arrangement.

## Contract

The exported `i64_array_scalar` function accepts exactly `[n,k]`, where
`1 <= n <= 20` and `1 <= k <= n`. It returns the exact integer count of
permutations whose disjoint-cycle decomposition has no cycle longer than
`k`. A malformed, null, or out-of-domain input returns `-1`.

The maximum result is `20! = 2,432,902,008,176,640,000`, below
`INT64_MAX = 9,223,372,036,854,775,807`. For every DP term, the falling
factorial `(s-1)!/(s-j)!` counts the possible directed cycles of length `j`
through one fixed label; multiplying it by `C[s-j]` counts the remaining
labels. Every term and every partial sum counts a subset of permutations on
`s <= 20` labels, so all intermediate positive values are at most `20!` and
fit signed 64-bit arithmetic.

## Primary recurrence and complexity

Set `C[0] = 1`. For each `s` from 1 through `n`, compute

```text
C[s] = sum(j = 1 .. min(s,k)) ((s-1)! / (s-j)!) * C[s-j]
```

This chooses the cycle containing a distinguished label, then independently
counts valid cycle decompositions on the remaining `s-j` labels. The ports
use the equivalent incremental falling-factorial product, avoiding factorial
division. Runtime is `O(n * min(n,k))`; the table uses `O(n)` signed 64-bit
words.

The primary Python reference implements this fixed-label recurrence. The
independent reference enumerates integer cycle types and sums
`n! / product(j^a_j * a_j!)`; it does not use the fixed-label recurrence.

## Provenance and distinctness

The pinned RosettaCodeData [popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
supplied the title “100 prisoners” and its score for discovery only. Method
context comes from Curtin and Warshauer, “The Locker Puzzle,”
*The Mathematical Intelligencer* 28(1), 2006,
[DOI 10.1007/BF02986999](https://doi.org/10.1007/BF02986999), and the
[article PDF](https://www.cl.cam.ac.uk/~gw104/Locker_Puzzle.pdf). The source
describes the cycle-following strategy and its success condition. This
benchmark generalizes the opening limit to `k` and returns the exact count
rather than a probability or simulated result.

Local permutation packages enumerate permutations or count unrestricted
partial permutations. `functional_graph_cycle_parameters` analyzes one given
successor map, while `problem95` follows aliquot-sequence orbits. None counts
permutations by a maximum allowed cycle length.

## Package files

- [`workload.json`](workload.json) contains bounded valid counts and malformed
  frames.
- [`primary_oracle.py`](primary_oracle.py) and
  [`independent_oracle.py`](independent_oracle.py) define separate exact
  references.
- [`verify_workload.py`](verify_workload.py) checks fixture framing,
  agreement of the two references, metadata, documentation, and source-port
  presence. It is provided as source and has not been run.
- [`RIGHTS.md`](RIGHTS.md) records clean-room provenance and source use.
- [`INVENTORY.md`](INVENTORY.md) lists the bounded contract and all ports.

No task text, submissions, code, examples, tests, or fixtures from Rosetta
Code were reused.

## Implementations

| Language | Source |
|---|---|
| C | [`c/r/random_permutation_cycle_cap_count.c`](../../../c/r/random_permutation_cycle_cap_count.c) |
| C3 | [`c3/r/random_permutation_cycle_cap_count.c3`](../../../c3/r/random_permutation_cycle_cap_count.c3) |
| C++ | [`cpp/r/random_permutation_cycle_cap_count.cpp`](../../../cpp/r/random_permutation_cycle_cap_count.cpp) |
| Elisa | [`elisa/r/random_permutation_cycle_cap_count.elisa`](../../../elisa/r/random_permutation_cycle_cap_count.elisa) |
| Mojo | [`mojo/r/random_permutation_cycle_cap_count.mojo`](../../../mojo/r/random_permutation_cycle_cap_count.mojo) |
| Nim | [`nim/r/random_permutation_cycle_cap_count.nim`](../../../nim/r/random_permutation_cycle_cap_count.nim) |
| Odin | [`odin/r/random_permutation_cycle_cap_count.odin`](../../../odin/r/random_permutation_cycle_cap_count.odin) |
| Rust | [`rust/r/random_permutation_cycle_cap_count.rs`](../../../rust/r/random_permutation_cycle_cap_count.rs) |
| V | [`v/r/random_permutation_cycle_cap_count.v`](../../../v/r/random_permutation_cycle_cap_count.v) |
| Zig | [`zig/r/random_permutation_cycle_cap_count.zig`](../../../zig/r/random_permutation_cycle_cap_count.zig) |
