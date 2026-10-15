# Jaccard similarity

Compute the intersection-over-union similarity for two finite sets of ASCII characters.

## Contract

- The `i64_array_float64` ABI accepts `[lengthA, lengthB, valuesA..., valuesB...]` and returns `|A ∩ B| / |A ∪ B|` as binary64.
- Each set has 0 through 64 distinct printable ASCII code points (32 through 126). The combined set must be nonempty.
- Malformed lengths, repeated characters within either set, nonprintable values, or two empty sets return `-1e300`.
- Valid outputs use relative and absolute tolerances of `1e-12`.

## Source semantics

This uses the default intersection-over-union behavior from pinned [TheAlgorithms Python `jaccard_similarity.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/jaccard_similarity.py), [C# `JaccardSimilarity.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/JaccardSimilarity.cs), and [MATLAB `jaccard_similarity.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/maths/jaccard_similarity.m). The unique printable ASCII subset makes Python list membership, C# character sets, and MATLAB numeric arrays represent the same sets. The benchmark reports the ratio in `[0,1]`; MATLAB's percentage output is normalized by dividing by 100. The Python `alternative_union` option is not selected. Both-empty input is excluded because the pinned Python source divides by zero there.

## Workload

[`workload.json`](workload.json) includes the documented 0.375 example, identical, disjoint, partially overlapping, and one-empty sets, plus invalid packed layouts.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/j/jaccard_similarity.c`](../../../c/j/jaccard_similarity.c) |
| C3 | [`c3/j/jaccard_similarity.c3`](../../../c3/j/jaccard_similarity.c3) |
| C++ | [`cpp/j/jaccard_similarity.cpp`](../../../cpp/j/jaccard_similarity.cpp) |
| Elisa | [`elisa/j/jaccard_similarity.elisa`](../../../elisa/j/jaccard_similarity.elisa) |
| Nim | [`nim/j/jaccard_similarity.nim`](../../../nim/j/jaccard_similarity.nim) |
| Odin | [`odin/j/jaccard_similarity.odin`](../../../odin/j/jaccard_similarity.odin) |
| Rust | [`rust/j/jaccard_similarity.rs`](../../../rust/j/jaccard_similarity.rs) |
| V | [`v/j/jaccard_similarity.v`](../../../v/j/jaccard_similarity.v) |
| Zig | [`zig/j/jaccard_similarity.zig`](../../../zig/j/jaccard_similarity.zig) |

The package uses the `i64_array_float64` benchmark ABI.
