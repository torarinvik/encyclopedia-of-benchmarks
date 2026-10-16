# Collaborative filtering Pearson similarity

This benchmark follows the separate `CalculateSimilarity` method in the pinned C# `CollaborativeFiltering` class. It computes Pearson correlation using only ratings for item IDs present in both profiles.

## Contract

- Pack `[first_count, item_id, rating_milli, ..., second_count, item_id, rating_milli, ...]`. Each profile preserves its dictionary insertion order; item IDs are unique within a profile.
- Each profile contains 0 through 32 items. Item IDs are 0 through 127. A rating is `rating_milli / 1,000.0`, with ticks from -1,000,000,000 through 1,000,000,000.
- The means are computed over the common item IDs in first-profile order. Return the centered cross-product sum divided by the square root of the product of centered square sums. Return 0 when there are no common items or the denominator magnitude is below `1e-10`, matching the source.
- Malformed input returns `-2.0`, outside the valid Pearson result range [-1, 1]. The rating grid adapts the source's binary64 dictionary values to the signed-i64-array ABI.

This source method is distinct from the class's `PredictRating` operation, benchmarked at [`collaborative_filtering`](../collaborative_filtering/README.md). Prediction uses an injected similarity calculator and does not call this Pearson method itself.

## Source

- [TheAlgorithms/C-Sharp `CollaborativeFiltering.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/RecommenderSystem/CollaborativeFiltering.cs), commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`.
- [TheAlgorithms/C-Sharp `ISimilarityCalculator.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/RecommenderSystem/ISimilarityCalculator.cs).

Build and record with `i64_array_float64`:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm collaborative_filtering_pearson_similarity --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/c/collaborative_filtering_pearson_similarity/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm collaborative_filtering_pearson_similarity
```

[`workload.json`](workload.json) covers identical and reversed profiles, a nontrivial 0.5 correlation, partial and empty overlap, constant profiles, the maximum profile size, and malformed layouts. The independent expected-result logic is in [`collaborative_filtering_oracle.py`](../../collaborative_filtering_oracle.py).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/collaborative_filtering_pearson_similarity.c`](../../../c/c/collaborative_filtering_pearson_similarity.c) |
| C3 | [`c3/collaborative_filtering_pearson_similarity.c3`](../../../c3/c/collaborative_filtering_pearson_similarity.c3) |
| C++ | [`cpp/collaborative_filtering_pearson_similarity.cpp`](../../../cpp/c/collaborative_filtering_pearson_similarity.cpp) |
| Elisa | [`elisa/collaborative_filtering_pearson_similarity.elisa`](../../../elisa/c/collaborative_filtering_pearson_similarity.elisa) |
| Nim | [`nim/collaborative_filtering_pearson_similarity.nim`](../../../nim/c/collaborative_filtering_pearson_similarity.nim) |
| Odin | [`odin/collaborative_filtering_pearson_similarity.odin`](../../../odin/c/collaborative_filtering_pearson_similarity.odin) |
| Rust | [`rust/collaborative_filtering_pearson_similarity.rs`](../../../rust/c/collaborative_filtering_pearson_similarity.rs) |
| V | [`v/collaborative_filtering_pearson_similarity.v`](../../../v/c/collaborative_filtering_pearson_similarity.v) |
| Zig | [`zig/collaborative_filtering_pearson_similarity.zig`](../../../zig/c/collaborative_filtering_pearson_similarity.zig) |
