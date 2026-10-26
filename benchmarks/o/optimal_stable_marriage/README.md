# Minimum-Regret Stable Marriage

This package implements the minimum-regret stable-marriage objective summarized in the *Encyclopedia of Algorithms*, DOI suffix 271. It is a distinct optimization objective from the men's-optimal stable matching in [`stable_matching`](../../s/stable_matching/README.md).

## Contract

- ABI: `i64_array_bytes_output`; symbol: `optimal_stable_marriage`.
- Input is `[n, men_preferences[n*n], women_preferences[n*n]]`, with complete strict preference rows and `0 <= n <= 8`.
- The regret of a matching is the largest zero-based rank assigned to any participant. The package finds a stable matching minimizing this value. Ties use the men-optimal stable matching among the optimum-regret matchings.
- The implementation searches regret thresholds in increasing order. At each threshold, it removes a pair if either participant ranks the other below the threshold, then runs men-proposing deferred acceptance on the remaining acceptable pairs. The first threshold producing a perfect matching is optimal. This is the bounded complete-list specialization of minimum-regret stable matching.
- Output is `[man_id,woman_id,...]`, ordered by man ID, as little-endian signed i64 words. Invalid input returns `-1`; null or short output returns `-2` without writes. The maximum input has 129 integers and the maximum output is 128 bytes.

The chapter is by Robert W. Irving and summarizes the minimum-regret algorithm of Gusfield. This package is a clean-room implementation; it contains no copied source code or book prose. See [`RIGHTS.md`](RIGHTS.md) for attribution.

## Workload and independent check

[`workload.json`](workload.json) covers empty, single-person, threshold-increase, and maximum-size instances plus malformed framing, invalid preference rows, and output errors. The primary [oracle](../../optimal_stable_marriage_oracle.py) uses thresholded deferred acceptance. The independent [verifier](../../optimal_stable_marriage_verifier_oracle.py) enumerates assignments, rejects blocking pairs, and minimizes regret directly.

## Implementations

| Language | Port |
|---|---|
| C | [`c/o/optimal_stable_marriage.c`](../../../c/o/optimal_stable_marriage.c) |
| C3 | [`c3/o/optimal_stable_marriage.c3`](../../../c3/o/optimal_stable_marriage.c3) |
| C++ | [`cpp/o/optimal_stable_marriage.cpp`](../../../cpp/o/optimal_stable_marriage.cpp) |
| Elisa | [`elisa/o/optimal_stable_marriage.elisa`](../../../elisa/o/optimal_stable_marriage.elisa) |
| Nim | [`nim/o/optimal_stable_marriage.nim`](../../../nim/o/optimal_stable_marriage.nim) |
| Odin | [`odin/o/optimal_stable_marriage.odin`](../../../odin/o/optimal_stable_marriage.odin) |
| Rust | [`rust/o/optimal_stable_marriage.rs`](../../../rust/o/optimal_stable_marriage.rs) |
| V | [`v/o/optimal_stable_marriage.v`](../../../v/o/optimal_stable_marriage.v) |
| Zig | [`zig/o/optimal_stable_marriage.zig`](../../../zig/o/optimal_stable_marriage.zig) |
