# Online interval coloring

This package implements a bounded clean-room profile of the level-based online interval coloring algorithm summarized in “Online Interval Coloring.” It is distinct from offline interval partitioning/scheduling: each color is committed before later intervals arrive, and the level rule preserves the input arrival order.

## Contract

Input is `[interval_count, (left, right)...]` with 0–64 closed intervals, endpoints in `[-1000,1000]`, and exact length `1 + 2*interval_count`. Intervals are processed in input order; two intervals intersect when their closed ranges share any point, including an endpoint.

For each interval, choose the smallest level `k` such that adding it to the union of earlier intervals at levels `1..k` keeps the maximum point overlap at most `k`. Then use First Fit among earlier intersecting intervals at that same level. A level has a disjoint three-color range; the output color is `3*(k-1)+local_color`. The chapter's Kierstead–Trotter construction guarantees the per-level First-Fit coloring uses at most three colors. Maximum overlap is checked at interval start coordinates, where a closed-interval clique reaches its maximum.

Output is one little-endian signed i64 global color per interval in arrival order. The maximum valid input is 129 words; output is at most 512 bytes, with maximum color ID 191. Malformed input returns `-1`; a null output or insufficient capacity returns `-2` without writing. Empty input `[0]` returns zero bytes when the output pointer is non-null.

## Oracles

The primary oracle emits exact bytes using the prefix level rule. The independent verifier uses a grouped endpoint event sweep to compute clique peaks and independently checks the prescribed level and First-Fit choices.

## Source and rights

The algorithm was identified from “Online Interval Coloring,” in Ming-Yang Kao (ed.), *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_264`. The chapter summarizes the Kierstead–Trotter algorithm (1981). All package code is independently written from the mathematical description; no chapter prose, code, or pseudocode has been copied. The chapter remains subject to publisher rights. The repository's top-level license applies to these original implementations.

## Files

- Workload: [`workload.json`](workload.json)
- Primary oracle: [`online_interval_coloring_oracle.py`](../../online_interval_coloring_oracle.py)
- Independent verifier: [`online_interval_coloring_verifier_oracle.py`](../../online_interval_coloring_verifier_oracle.py)
- Nine language ports: `c/o`, `c3/o`, `cpp/o`, `elisa/o`, `nim/o`, `odin/o`, `rust/o`, `v/o`, and `zig/o`.
