# Minimum string representation

Return the zero-based start of a lexicographically least cyclic rotation of an
ASCII codepoint array. This package uses the linear two-candidate elimination
scan described in OI Wiki's *Minimal Representation* chapter. It is a separate
benchmark from [`duval`](../../d/duval/README.md): both return a least-rotation
index, but Duval advances by Lyndon factorization while this scan compares and
eliminates two candidate starts. Tied minimal rotations return the smallest
surviving candidate index.

## Input and ABI

The exported C ABI symbol is
`minimum_string_representation(const int64_t *values, size_t length)` using
`i64_array_scalar`.

Input is a signed 64-bit array of 0 to 4,096 values, each in `0..=127`. The
return value is an index in `0..length`; empty input returns 0. Invalid length,
a null pointer for nonempty input, or a non-ASCII codepoint returns -1. Input is
not modified. Maximum valid input length is 4,096; the bounded harness can
represent one extra element when checking the overlength error path.

## Algorithm and complexity

Keep two candidate starts `i` and `j` and an equal-prefix length `k`. Compare
the cyclic symbols at `i+k` and `j+k`. Equal symbols extend the common prefix.
At the first mismatch, advance the candidate with the larger symbol by `k+1`,
skip it past the other candidate if they meet, and reset `k`. At least one
candidate survives below `n`; its smaller index is returned. The scan takes
O(n) comparisons and O(1) auxiliary storage.

The primary oracle mirrors candidate elimination. The independent verifier
compares every cyclic rotation directly and selects the earliest minimum; its
O(n^2) bound is practical for this profile's maximum length of 4,096.

## Sources and ports

The implementation is clean-room and follows the algorithm description in
[OI Wiki: Minimal Representation](https://en.oi-wiki.org/string/minimal-string/).
The page is CC BY-SA 4.0 with SATA terms; this repository uses only its
algorithm description. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/m/minimum_string_representation.c`](../../../c/m/minimum_string_representation.c) |
| C3 | [`c3/m/minimum_string_representation.c3`](../../../c3/m/minimum_string_representation.c3) |
| C++ | [`cpp/m/minimum_string_representation.cpp`](../../../cpp/m/minimum_string_representation.cpp) |
| Elisa | [`elisa/m/minimum_string_representation.elisa`](../../../elisa/m/minimum_string_representation.elisa) |
| Mojo | [`mojo/m/minimum_string_representation.mojo`](../../../mojo/m/minimum_string_representation.mojo) |
| Nim | [`nim/m/minimum_string_representation.nim`](../../../nim/m/minimum_string_representation.nim) |
| Odin | [`odin/m/minimum_string_representation.odin`](../../../odin/m/minimum_string_representation.odin) |
| Rust | [`rust/m/minimum_string_representation.rs`](../../../rust/m/minimum_string_representation.rs) |
| V | [`v/m/minimum_string_representation.v`](../../../v/m/minimum_string_representation.v) |
| Zig | [`zig/m/minimum_string_representation.zig`](../../../zig/m/minimum_string_representation.zig) |

The fixed cases are in [`workload.json`](workload.json). The primary and
independent oracle modules are
[`minimum_string_representation_oracle.py`](../../minimum_string_representation_oracle.py)
and
[`minimum_string_representation_verifier_oracle.py`](../../minimum_string_representation_verifier_oracle.py).
