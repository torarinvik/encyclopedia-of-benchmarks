# JuntaTest partition binary-search replay

This package benchmarks the bounded deterministic trace of Eric Blais's `JuntaTest` algorithm from §3.1, Figure 1 of [“Testing Juntas Nearly Optimally”](https://www.cs.cmu.edu/~eblais/papers/TestingJuntas.pdf). The Encyclopedia of Algorithms [Chapter 709](https://doi.org/10.1007/978-1-4939-2864-4_709) is the coverage context. The local package search found no junta tester; the influence-maximization packages use graph diffusion and do not test Boolean functions for junta structure.

The profile fixes the uniform Boolean domain to `n<=8`, `k=1`, `epsilon=1`, and 24 rounds. It takes the function as a packed truth table, an ordered partition of the coordinates, and 24 supplied sample pairs. The source's partition count is `s=10^20` for this fixed parameter choice; since `s` exceeds the bounded domain, the frame stores only the occupied groups, in their original order, and omits empty groups. The source's random partition and random sample generation are not performed.

## Input and output

The input is a signed i64 array:

```text
[n, part_count, truth_word_count, packed_truth_words..., part_id[0..n-1], pair[0..23]]
```

There are `ceil(2^n/64)` truth words. Assignment `x` is the table bit `x mod 64` in word `floor(x/64)`. Coordinate zero is the least-significant bit of an assignment mask. Unused high truth-table bits must be zero. `part_id[i]` is in `0..part_count-1`; every group ID must occur, so the ordered nonempty partition is fully specified. A pair word packs sample `x` in its low `n` bits and sample `y` in its next `n` bits. Each point is in `{0,1}^n`.

The frame has at most 39 valid words and accepts at most 40 parseable words so a trailing-value probe can be rejected. Output is little-endian signed i64 words:

```text
[decision, found_count, oracle_query_count, (round_index, selected_part_id)*found_count]
```

`decision` is zero for accept and one for reject. The algorithm rejects immediately after finding a second distinct relevant partition group. Thus the maximum output is seven words (56 bytes). Invalid input returns `-1` with no output; null or short output returns `-2` with no output. Fixed arrays, endpoint state, and output staging fit within the 4,096-byte workspace allowance.

## Replay semantics

Initialize the active coordinate set `S` to all coordinates. In every round compare `f(x)` with `f(z)`, where `z` takes `y` on active coordinates and `x` on removed coordinates. If the outputs agree, continue. Otherwise, the two assignments differ only across active partition groups. Binary-search the ordered active group list: split it at `floor(length/2)`, query a hybrid that takes the right endpoint's bits on the lower half and the left endpoint's bits elsewhere, and retain the half whose endpoint pair has unequal function values. Once one group remains, remove that group's coordinates from `S`, record its group ID and round, and reject if this is the second group. Accept after all 24 rounds if no second group was found.

The paper states the binary-search idea but does not prescribe a split order or hybrid tie convention. The ordered midpoint rule above is the deterministic refinement used by this benchmark. Query count includes the two function evaluations in each entered outer round plus each binary-search probe; endpoints are not re-queried. With input length `L`, fixed `r=24`, and `k=1`, the bounded implementation takes `O(L + r + (k+1)n)` time: constructing a candidate-group list and the successive half masks costs O(n) per successful search. Each function evaluation is one truth-table bit lookup. Workspace is `O(n + output_words)` beyond the caller-owned frame.

This is deterministic transcript replay. The supplied partition and sample tape replace randomness, so the package makes no completeness, soundness, or probability guarantee about any particular fixture. It measures the outer rejection logic and the binary-search-over-groups kernel, not the random tester as a randomized experiment.

## Ports and package artifacts

The ten native ports are listed in [INVENTORY.md](INVENTORY.md) and `inventory.json`. The primary reference uses coordinate bit masks; the independent reference expands the truth table and endpoints into Boolean coordinate vectors. `workload.json` pins constant, one-junta, two-group rejection, merged-group, single-group, maximum-frame, malformed-frame, short-output, and null-input cases. Static consistency helpers are provided but were not run.
