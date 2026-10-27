# Johnson–Trotter adjacent-swap permutation Gray code

This package implements the chapter's Johnson–Trotter adjacent-swap Gray code
for permutations of `[n]`. It begins at `1,2,...,n`; each value has a moving
direction. The next row swaps the largest mobile value with its neighbor in
that direction, then reverses the directions of all larger values. A value is
mobile when its directed neighbor exists and is smaller. Enumeration stops
when no value is mobile.

This is distinct from the repository-backed
[`steinhaus_johnson_trotter`](../../s/steinhaus_johnson_trotter/README.md)
package: that Rust-derived inversion-vector order can make non-adjacent
changes, so it does not implement the chapter's Gray-code contract.

The bounded input is `[n]`, for `1 <= n <= 3`. Output contains every
permutation as consecutive rows of `n` little-endian signed 64-bit integers,
in the exact Johnson–Trotter order. Maximum output is 144 bytes. The small
bound keeps this source-algorithm profile suitable for the cross-language
suite. Invalid framing or an unsupported `n` returns `-1`; null output or
insufficient capacity returns `-2` without writes.

The primary oracle simulates mobile-element swaps. The independent verifier
builds the same Gray-code order through recursive reflected insertion of the
largest value and packs those rows independently.

Source: “Permutation Enumeration,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_735`](https://doi.org/10.1007/978-1-4939-2864-4_735).
This package is a clean-room implementation and does not reproduce book text,
figures, or code. See [RIGHTS.md](RIGHTS.md).

## Workload and ports

The [workload](workload.json) covers identity, the two-element swap, the
three-element Gray-code sequence, malformed input, null buffers, and output
capacity boundaries.

| Language | Port |
| --- | --- |
| C | [`c/j/johnson_trotter_adjacent_gray_code.c`](../../../c/j/johnson_trotter_adjacent_gray_code.c) |
| C3 | [`c3/j/johnson_trotter_adjacent_gray_code.c3`](../../../c3/j/johnson_trotter_adjacent_gray_code.c3) |
| C++ | [`cpp/j/johnson_trotter_adjacent_gray_code.cpp`](../../../cpp/j/johnson_trotter_adjacent_gray_code.cpp) |
| Elisa | [`elisa/j/johnson_trotter_adjacent_gray_code.elisa`](../../../elisa/j/johnson_trotter_adjacent_gray_code.elisa) |
| Nim | [`nim/j/johnson_trotter_adjacent_gray_code.nim`](../../../nim/j/johnson_trotter_adjacent_gray_code.nim) |
| Odin | [`odin/j/johnson_trotter_adjacent_gray_code.odin`](../../../odin/j/johnson_trotter_adjacent_gray_code.odin) |
| Rust | [`rust/j/johnson_trotter_adjacent_gray_code.rs`](../../../rust/j/johnson_trotter_adjacent_gray_code.rs) |
| V | [`v/j/johnson_trotter_adjacent_gray_code.v`](../../../v/j/johnson_trotter_adjacent_gray_code.v) |
| Zig | [`zig/j/johnson_trotter_adjacent_gray_code.zig`](../../../zig/j/johnson_trotter_adjacent_gray_code.zig) |
