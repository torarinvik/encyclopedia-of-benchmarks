# Jaro-Winkler distance

This benchmark follows the pinned C# `JaroWinklerDistance.Calculate` behavior. It uses the default scaling factor 0.1 and returns distance, so identical strings score zero.

## Contract

Input is a signed 64-bit array `[s1_length, s1_ascii..., s2_length, s2_ascii...]`. Each string has 0–32 ASCII code units, encoded as values 0–127, with `s1_length >= s2_length`. The order restriction preserves the pinned C# helper's indexing behavior: it loops over the longer string while indexing `s1`. The packed array must have exactly `2 + s1_length + s2_length` elements.

For nonempty strings, Jaro matching uses radius `max(floor(longer_length / 2) - 1, 0)`. It scans `s1` left to right, greedily matches each position to the first unmatched equal code unit in the inclusive window, counts mismatched pairs among matched positions in order, and integer-divides that count by two for transpositions. Jaro is the average of the two match ratios and the adjusted match ratio. The wrapper always applies the common-prefix boost for up to four code units, then returns `1 - similarity`.

The result is an integer fixed-point distance in `[0, 1_000_000_000]`, rounded to the nearest integer with ties upward. The ports compute from integer rational terms so all languages use the same rounding. Equal strings, including two empty strings, return 0. A valid nonempty `s1` with an empty `s2`, or a pair with no Jaro matches, returns 1,000,000,000. Malformed layout, an out-of-range code unit, or a string outside the bounds returns -1.

The pinned Rust file named `jaro_winkler_distance` is documented as a nonmatching candidate: it returns similarity rather than distance and uses different matching logic. The shared contract follows the C# wrapper and its `JaroSimilarity.Calculate` helper.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm jaro_winkler_distance --language LANGUAGE
python3 benchmarks/run_i64_array_scalar.py --algorithm jaro_winkler_distance
python3 benchmarks/verify_i64_array_scalar.py --algorithms jaro_winkler_distance
```

## Pinned sources

- C# [`JaroWinklerDistance.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/JaroWinklerDistance.cs) and helper [`JaroSimilarity.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/JaroSimilarity.cs).
- Rust [`jaro_winkler_distance.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/jaro_winkler_distance.rs), recorded as semantically divergent from the C# distance contract.
