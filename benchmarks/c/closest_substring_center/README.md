# Bounded exact closest-substring center

This package implements the closest-substring problem defined in “Closest String and Substring Problems,” *Encyclopedia of Algorithms*, DOI [10.1007/978-1-4939-2864-4_74](https://doi.org/10.1007/978-1-4939-2864-4_74). For each input string, the center is compared with its best length-`L` window; the objective minimizes the maximum of those per-string Hamming distances. The package uses exhaustive center enumeration for a small deterministic profile and does not claim to reproduce one of the chapter’s FPT or approximation schemes.

## Contract

Input is `[n,m,L,q,strings[n*m]]` with `1<=n<=4`, `1<=m<=10`, `1<=L<=min(8,m)`, alphabet size `q` in `{2,3}`, and symbols in `[0,q)`. Output is `[minimum_radius, lexicographically smallest optimal center[L]]`, encoded as little-endian signed 64-bit values. The function returns `8*(L+1)`, `-1` for malformed input, and `-2` for a null or short output buffer. Exhaustive search is bounded by `3^8` centers.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/closest_substring_center.c`](../../../c/c/closest_substring_center.c) |
| C3 | [`c3/c/closest_substring_center.c3`](../../../c3/c/closest_substring_center.c3) |
| C++ | [`cpp/c/closest_substring_center.cpp`](../../../cpp/c/closest_substring_center.cpp) |
| Elisa | [`elisa/c/closest_substring_center.elisa`](../../../elisa/c/closest_substring_center.elisa) |
| Nim | [`nim/c/closest_substring_center.nim`](../../../nim/c/closest_substring_center.nim) |
| Odin | [`odin/c/closest_substring_center.odin`](../../../odin/c/closest_substring_center.odin) |
| Rust | [`rust/c/closest_substring_center.rs`](../../../rust/c/closest_substring_center.rs) |
| V | [`v/c/closest_substring_center.v`](../../../v/c/closest_substring_center.v) |
| Zig | [`zig/c/closest_substring_center.zig`](../../../zig/c/closest_substring_center.zig) |

Primary oracle: [`closest_substring_center_oracle.py`](../../closest_substring_center_oracle.py). Independent verifier: [`closest_substring_center_verifier_oracle.py`](../../closest_substring_center_verifier_oracle.py).

## Attribution and rights

The problem definition is attributed to Lusheng Wang, Ming Li, and Bin Ma, “Closest String and Substring Problems,” *Encyclopedia of Algorithms* (2016), DOI 10.1007/978-1-4939-2864-4_74. No book prose, figures, or code are reproduced; the ports are independently written. Attribution does not grant rights to redistribute the book.
