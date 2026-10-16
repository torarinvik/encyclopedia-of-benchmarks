# Collaborative filtering prediction

This benchmark follows `PredictRating` in the pinned C# `CollaborativeFiltering` class. It covers the method's weighted prediction after an injected `ISimilarityCalculator` supplies one similarity per other user. It keeps those injected similarities as explicit inputs; the source does not hardwire its Pearson method into prediction.

## Contract

- Pack `[user_count, is_target_user, has_target_rating, similarity_ticks, rating_milli, ...]`. Each user has one four-value record in dictionary enumeration order. Exactly one record identifies the target user, matching the source's `user.Key == targetUser` skip.
- `user_count` is 1 through 65: the target user plus at most 64 other users. Both flags are 0 or 1. The target-user record is skipped; other records with `has_target_rating == 0` are skipped, matching the source's target-user and `ContainsKey(targetItem)` guards.
- Similarity and rating fields on the target-user record and on neighbors with `has_target_rating == 0` are ignored after their ranges are checked. For each eligible neighbor, injected similarity is the value returned by the source's `ISimilarityCalculator`; this benchmark does not prescribe how that calculator works.
- Similarity is `similarity_ticks / 1,000,000,000,000.0`, with ticks from -1,000,000,000,000 through 1,000,000,000,000. Rating is `rating_milli / 1,000.0`, with ticks from -1,000,000,000 through 1,000,000,000. These decimal grids make the binary64 source inputs portable through the shared signed-i64-array ABI.
- In input order, accumulate `weighted_sum += similarity * rating` and `total_similarity += abs(similarity)`. Return `weighted_sum / total_similarity`, or 0 when `abs(total_similarity) < 1e-10`, as in the source. Malformed input returns `-1e300`.
- The bound on ratings keeps every valid result in [-1,000,000, 1,000,000], separate from the invalid sentinel.

The source's unit test injects similarity 0.8 for two neighbors rated 4 and 3; this workload preserves that example and its result, 3.5. The class's Pearson method is benchmarked separately at [`collaborative_filtering_pearson_similarity`](../collaborative_filtering_pearson_similarity/README.md).

## Source

- [TheAlgorithms/C-Sharp `CollaborativeFiltering.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/RecommenderSystem/CollaborativeFiltering.cs), commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`.
- [TheAlgorithms/C-Sharp `ISimilarityCalculator.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/RecommenderSystem/ISimilarityCalculator.cs) defines the injected similarity API; [the tests](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms.Tests/RecommenderSystem/CollaborativeFilteringTests.cs) use a constant similarity of 0.8.

Build and record with `i64_array_float64`:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm collaborative_filtering --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/c/collaborative_filtering/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm collaborative_filtering
```

[`workload.json`](workload.json) covers the source test example, signed and missing-neighbor cases, the strict epsilon boundary, the maximum neighbor count, and invalid input. The independent expected-result logic is in [`collaborative_filtering_oracle.py`](../../collaborative_filtering_oracle.py).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/collaborative_filtering.c`](../../../c/c/collaborative_filtering.c) |
| C3 | [`c3/collaborative_filtering.c3`](../../../c3/c/collaborative_filtering.c3) |
| C++ | [`cpp/collaborative_filtering.cpp`](../../../cpp/c/collaborative_filtering.cpp) |
| Elisa | [`elisa/collaborative_filtering.elisa`](../../../elisa/c/collaborative_filtering.elisa) |
| Nim | [`nim/collaborative_filtering.nim`](../../../nim/c/collaborative_filtering.nim) |
| Odin | [`odin/collaborative_filtering.odin`](../../../odin/c/collaborative_filtering.odin) |
| Rust | [`rust/collaborative_filtering.rs`](../../../rust/c/collaborative_filtering.rs) |
| V | [`v/collaborative_filtering.v`](../../../v/c/collaborative_filtering.v) |
| Zig | [`zig/collaborative_filtering.zig`](../../../zig/c/collaborative_filtering.zig) |
