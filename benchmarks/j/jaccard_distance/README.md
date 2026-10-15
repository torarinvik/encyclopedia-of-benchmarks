# Jaccard distance

Compute one minus the character-set Jaccard similarity for two strings.

## Contract

- The `i64_array_float64` ABI accepts `[lengthA, lengthB, charsA..., charsB...]` and returns `1 - |A ∩ B| / |A ∪ B|`, treating each string as a set of characters.
- Each string contains 0 through 64 printable ASCII code points (32 through 126). Repeated characters are accepted and count once, matching the source `HashSet<char>` behavior.
- Two empty strings return `0`; one empty string and one nonempty string return `1`.
- Malformed lengths or nonprintable values return `-1e300`.
- Valid outputs use relative and absolute tolerances of `1e-12`.

## Source semantics

This follows the pinned [TheAlgorithms C# `JaccardDistance.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/JaccardDistance.cs), which returns one minus its `JaccardSimilarity.Calculate` result. That implementation uses `HashSet<char>`, so repeated input characters do not change the set; when both strings are empty, similarity is 1 and distance is 0. The packed ABI cannot represent null strings, and the benchmark limits characters to printable ASCII for a portable cross-language contract.

## Workload

[`workload.json`](workload.json) covers the source's sample set relationship, duplicates, equal/disjoint/empty sets, and invalid packed layouts.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/j/jaccard_distance.c`](../../../c/j/jaccard_distance.c) |
| C3 | [`c3/j/jaccard_distance.c3`](../../../c3/j/jaccard_distance.c3) |
| C++ | [`cpp/j/jaccard_distance.cpp`](../../../cpp/j/jaccard_distance.cpp) |
| Elisa | [`elisa/j/jaccard_distance.elisa`](../../../elisa/j/jaccard_distance.elisa) |
| Nim | [`nim/j/jaccard_distance.nim`](../../../nim/j/jaccard_distance.nim) |
| Odin | [`odin/j/jaccard_distance.odin`](../../../odin/j/jaccard_distance.odin) |
| Rust | [`rust/j/jaccard_distance.rs`](../../../rust/j/jaccard_distance.rs) |
| V | [`v/j/jaccard_distance.v`](../../../v/j/jaccard_distance.v) |
| Zig | [`zig/j/jaccard_distance.zig`](../../../zig/j/jaccard_distance.zig) |

The package uses the `i64_array_float64` benchmark ABI.
