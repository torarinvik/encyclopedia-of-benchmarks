# Small Multiple via shortest path modulo

For an integer `n`, find the smallest possible digit sum among positive
decimal multiples of `n` whose digits are only `0` and `1`.

## Contract

- Input is exactly `[n]`, where `1 <= n <= 16`.
- Return the minimum digit sum of a positive multiple of `n` written using
  only decimal digits zero and one. Malformed input returns `-1`.
- Each residue modulo `n` is a graph vertex. From residue `r`, appending a
  zero reaches `10r mod n` at cost zero, while appending a one reaches
  `(10r+1) mod n` at cost one. Start at residue `1 mod n` with cost one;
  the shortest distance to residue zero is the answer.
- The primary port uses 0-1 BFS. A shortest residue path can discard cycles
  without increasing its digit sum, so at most `n` digits are needed. The
  independent reference exhaustively enumerates every leading-one string up
  to that length. At the largest input it examines fewer than 65,536 strings.
- The maximum parseable input length is two, allowing a trailing-value framing
  case; exactly one value is valid.

The exact task is OI Wiki's ARC084B Example 2, [Small Multiple](https://atcoder.jp/contests/arc084/tasks/arc084_b).
The residue-graph construction is described in the [OI Wiki method article](https://www.timothywang.ca/OI-wiki/graph/mod-shortest-path/).
This package uses that algorithmic idea only. See [RIGHTS.md](RIGHTS.md) for
provenance. The ten source ports and static workload references are listed in
[INVENTORY.md](INVENTORY.md); scalar-suite wiring is handled separately.

## Language ports

- [C](../../../c/s/shortest_path_modulo_small_multiple.c)
- [C3](../../../c3/s/shortest_path_modulo_small_multiple.c3)
- [C++](../../../cpp/s/shortest_path_modulo_small_multiple.cpp)
- [Elisa](../../../elisa/s/shortest_path_modulo_small_multiple.elisa)
- [Mojo](../../../mojo/s/shortest_path_modulo_small_multiple.mojo)
- [Nim](../../../nim/s/shortest_path_modulo_small_multiple.nim)
- [Odin](../../../odin/s/shortest_path_modulo_small_multiple.odin)
- [Rust](../../../rust/s/shortest_path_modulo_small_multiple.rs)
- [V](../../../v/s/shortest_path_modulo_small_multiple.v)
- [Zig](../../../zig/s/shortest_path_modulo_small_multiple.zig)
