# Singly-even magic square (Strachey method)

Construct the canonical singly-even normal magic square using Strachey's
quadrant construction. This fills the gap left by `magic_square`, which covers
only odd orders.

## Contract

- `scalar_call` accepts one signed 64-bit order `n` and returns a signed 64-bit
  scalar.
- Valid orders are `6 <= n <= 30` with `n % 4 == 2`. All other inputs return
  `-1`.
- Construct an odd-order Siamese square of side `u = n / 2`, starting with 1
  in the top row's center. Place translated copies in quadrants A/C over D/B:
  A is top-left with values `1..u²`; B is bottom-right with offset `u²`; C is
  top-right with offset `2u²`; D is bottom-left with offset `3u²`.
- With `k = u / 2`, exchange the first `k` columns of A and D, then exchange
  the last `k - 1` columns of C and B. In the middle row, exchange the first
  A/D cell back, then exchange A/D's central cell.
- Return the low 63 bits of FNV-1a-64 over `n` as one unsigned byte, followed
  by the square's row-major signed 32-bit little-endian entries. Use offset
  `0xcbf29ce484222325` and prime `0x100000001b3` with 64-bit wraparound.

The maximum order keeps the fixed work arrays and all cell values in range.
The orientation and swap order are pinned by this profile because rotated or
otherwise equivalent magic squares produce different checksums.

## Workload and references

[`workload.json`](workload.json) supplies valid and invalid scalar inputs;
expected scalar values are obtained from the primary oracle. The primary
reference constructs the odd sub-square with the Siamese walk. The independent
oracle places each sub-square value using a direct modular inverse formula and
checks the normal magic-square invariants before hashing.

- [Strachey construction in the *Journal of Integer Sequences*, Vol. 27 (2024), §2](https://cs.uwaterloo.ca/journals/JIS/VOL27/Chia/chia6.pdf)
- [Independent singly-even construction discussion, CUNY–Queensborough paper, pp. 6–9](https://www.qcc.cuny.edu/engtech/ET_Faculty/Brumgnach/Magic_Squares/Gamma_plus_two_method_for_odd_magic_squares.pdf)
- [RosettaGit public task title index](https://rosettagit.org/tasks/) (title/category used only for gap discovery)

Ten language ports use the repository's scalar-call ABI and live in their
respective `m` folders. The static inventory checker checks package metadata
and source presence; it does not execute implementations.
