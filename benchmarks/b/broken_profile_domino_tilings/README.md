# Broken-profile domino tilings

Count domino tilings of an open `H` by `W` rectangular grid, modulo
998244353. A domino covers two orthogonally adjacent cells. The clean-room
ports use a frontier-mask dynamic program: the mask records cells already
occupied by vertical dominoes arriving from the previous row; each row
transition chooses vertical dominoes leaving downward and covers the other
free cells with horizontal pairs. The board is transposed logically when
needed so the mask width is `min(H,W)`.

The local contract accepts `1<=H,W<=64`, `min(H,W)<=8`, and `H*W<=512`.
This is a bounded profile and does not claim the scale of any external judge.

## ABI

Symbol: `broken_profile_domino_tilings`; ABI `i64_array_scalar_call`.
Input is `[H,W]`; malformed dimensions return `-1`. Otherwise the result is
the tiling count modulo 998244353. The primary oracle uses a frontier-mask
transition DP. A direct first-empty-cell enumeration is provided for small
boards, and the independent verifier builds explicit row-transition lists.

## Provenance and rights

The profile method is attributed to CP-Algorithms' [Dynamic Programming on
Broken Profile](https://cp-algorithms.com/dynamic_programming/profile-dynamics.html),
licensed CC BY-SA 4.0. The ports and oracles are clean-room implementations;
they include no copied article prose or source code. See [RIGHTS.md](RIGHTS.md)
and [workload.json](workload.json). The production profile oracle is
[`broken_profile_domino_tilings_oracle.py`](../../broken_profile_domino_tilings_oracle.py);
the independent row-transition checker is
[`broken_profile_domino_tilings_verifier_oracle.py`](../../broken_profile_domino_tilings_verifier_oracle.py).
The primary oracle also includes direct enumeration for boards of at most 30
cells, used only as a small-board cross-check.

## Ports

| Language | Source |
|---|---|
| C | [`c/b/broken_profile_domino_tilings.c`](../../../c/broken_profile_domino_tilings.c) |
| C3 | [`c3/b/broken_profile_domino_tilings.c3`](../../../c3/broken_profile_domino_tilings.c3) |
| C++ | [`cpp/b/broken_profile_domino_tilings.cpp`](../../../cpp/broken_profile_domino_tilings.cpp) |
| Elisa | [`elisa/b/broken_profile_domino_tilings.elisa`](../../../elisa/broken_profile_domino_tilings.elisa) |
| Mojo | [`mojo/b/broken_profile_domino_tilings.mojo`](../../../mojo/b/broken_profile_domino_tilings.mojo) |
| Nim | [`nim/b/broken_profile_domino_tilings.nim`](../../../nim/b/broken_profile_domino_tilings.nim) |
| Odin | [`odin/b/broken_profile_domino_tilings.odin`](../../../odin/b/broken_profile_domino_tilings.odin) |
| Rust | [`rust/b/broken_profile_domino_tilings.rs`](../../../rust/b/broken_profile_domino_tilings.rs) |
| V | [`v/b/broken_profile_domino_tilings.v`](../../../v/b/broken_profile_domino_tilings.v) |
| Zig | [`zig/b/broken_profile_domino_tilings.zig`](../../../zig/b/broken_profile_domino_tilings.zig) |
