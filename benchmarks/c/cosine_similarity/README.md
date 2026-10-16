# Cosine similarity

Measure the cosine similarity between two strings by treating each string as a vector of character frequencies. The pinned C# implementation lowercases both strings invariantly, counts each character, and computes the dot product divided by the product of the vector magnitudes.

## Contract

- Input is a signed 64-bit array `[left_length, right_length, left_bytes..., right_bytes...]` with each string length in `0..64` and each byte in printable ASCII `32..126`.
- ASCII uppercase letters are folded to lowercase before counting. All other printable bytes, including spaces and punctuation, are counted as their own symbols.
- Return the cosine similarity of the two frequency vectors. If either string is empty, return `0.0`. Similarity is in `[0, 1]`.
- With frequency vectors, a nonempty string remains nonzero even when every character is unique; the source comment describing unique characters as a zero vector does not match the calculation in its code.
- A wrong packed length, a string longer than 64 bytes, a null pointer, or a nonprintable byte returns `-1e300`.
- The 64-byte ASCII domain makes each byte correspond to one source `char` and keeps the invariant case-folding behavior portable.

## Workload and oracle

[`workload.json`](workload.json) covers empty strings, case folding, punctuation, frequency weighting, disjoint and identical character sets, maximum-length strings, and malformed inputs. The independent oracle counts printable-ASCII frequencies directly: [`cosine_similarity_oracle.py`](../../cosine_similarity_oracle.py).

## Reviewed source

[TheAlgorithms/C-Sharp `CosineSimilarity.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/CosineSimilarity.cs)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm cosine_similarity --language rust
python3 benchmarks/run_i64_array_float64.py --algorithm cosine_similarity
python3 benchmarks/verify_i64_array_float64.py --algorithm cosine_similarity
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/cosine_similarity.c`](../../../c/c/cosine_similarity.c) |
| C3 | [`c3/c/cosine_similarity.c3`](../../../c3/c/cosine_similarity.c3) |
| C++ | [`cpp/c/cosine_similarity.cpp`](../../../cpp/c/cosine_similarity.cpp) |
| Elisa | [`elisa/c/cosine_similarity.elisa`](../../../elisa/c/cosine_similarity.elisa) |
| Nim | [`nim/c/cosine_similarity.nim`](../../../nim/c/cosine_similarity.nim) |
| Odin | [`odin/c/cosine_similarity.odin`](../../../odin/c/cosine_similarity.odin) |
| Rust | [`rust/c/cosine_similarity.rs`](../../../rust/c/cosine_similarity.rs) |
| V | [`v/c/cosine_similarity.v`](../../../v/c/cosine_similarity.v) |
| Zig | [`zig/c/cosine_similarity.zig`](../../../zig/c/cosine_similarity.zig) |
