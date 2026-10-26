# Bounded exact closest-string center

This package implements the closest-string problem defined in “Closest String and Substring Problems,” *Encyclopedia of Algorithms*, DOI [10.1007/978-1-4939-2864-4_73](https://doi.org/10.1007/978-1-4939-2864-4_73). Given equal-length strings, it returns a center minimizing the maximum Hamming distance to any input string. This is a clean bounded exhaustive profile for the chapter’s problem definition; it does not claim to reproduce one of the chapter’s FPT or approximation schemes.

## Contract

Input is `[n,m,q,strings[n*m]]` with `1<=n<=6`, `1<=m<=8`, alphabet size `q` in `{2,3}`, and symbols in `[0,q)`. The output is `[minimum_radius, center_symbols[m]]`, encoded as little-endian signed 64-bit values. Among optimal centers, the lexicographically smallest is selected. The function returns `8*(m+1)`, `-1` for malformed input, and `-2` for a null or short output buffer. Exhaustive search is bounded by `3^8` candidate centers.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/closest_string_center.c`](../../../c/c/closest_string_center.c) |
| C3 | [`c3/c/closest_string_center.c3`](../../../c3/c/closest_string_center.c3) |
| C++ | [`cpp/c/closest_string_center.cpp`](../../../cpp/c/closest_string_center.cpp) |
| Elisa | [`elisa/c/closest_string_center.elisa`](../../../elisa/c/closest_string_center.elisa) |
| Nim | [`nim/c/closest_string_center.nim`](../../../nim/c/closest_string_center.nim) |
| Odin | [`odin/c/closest_string_center.odin`](../../../odin/c/closest_string_center.odin) |
| Rust | [`rust/c/closest_string_center.rs`](../../../rust/c/closest_string_center.rs) |
| V | [`v/c/closest_string_center.v`](../../../v/c/closest_string_center.v) |
| Zig | [`zig/c/closest_string_center.zig`](../../../zig/c/closest_string_center.zig) |

Primary oracle: [`closest_string_center_oracle.py`](../../closest_string_center_oracle.py). Independent verifier: [`closest_string_center_verifier_oracle.py`](../../closest_string_center_verifier_oracle.py).

## Attribution and rights

The problem definition is attributed to Lusheng Wang, Ming Li, and Bin Ma, “Closest String and Substring Problems,” *Encyclopedia of Algorithms* (2016), DOI 10.1007/978-1-4939-2864-4_73. No book prose, figures, or code are reproduced. The implementation is independently written; attribution does not grant rights to redistribute the book.
