# Four-square sum representation

## Contract

Input is the one-element array `[N]`, where `0 <= N <= 1024`. Return the
lexicographically greatest nonincreasing tuple `(a,b,c,d)` satisfying
`N=a²+b²+c²+d²` and `32>=a>=b>=c>=d>=0`. The tuple is packed as four base-33
digits, `(((a*33)+b)*33+c)*33+d`; decode the digits from most significant to
least significant to recover the components. Malformed input returns `-1`.
Every valid input has a representation by Lagrange's four-square theorem.

The primary enumerates `a`, `b`, and `c` in descending order and checks whether
the remaining value is a square. Its first match is canonical. It takes
`O(N^(3/2))` time and constant auxiliary space. The independent reference
indexes unordered pair sums and looks up the complementary pair in
lexicographic order, using `O(N)` bounded storage.

## Distinctness and provenance

The repository's [`two_square_sum`](../t/two_square_sum/README.md) enumerates
ordered two-term representations, while [`minimum_squares_to_represent_a_number`](../m/minimum_squares_to_represent_a_number/README.md)
returns only the minimum number of square terms. Neither returns a canonical
four-term representation. The bounded lexicographic decomposition is a
distinct workload.

The public Codewars title [“Express number as sum of four squares”](https://www.codewars.com/kata/63022799acfb8d00285b4ea0)
was used only to discover this topic. Mathematical context comes from Pollack
and Treviño, [“Finding the Four Squares in Lagrange's Theorem”](https://pollack.uga.edu/finding4squares.pdf).
No kata statement, examples, tests, solutions, or source code were consulted
or copied. Both implementations here are independently written bounded
searches; no external implementation text is reused.

## Workload

[`workload.json`](workload.json) covers small decompositions, the upper input
bound, malformed frames, and out-of-range values. The two Python references
are `primary_oracle.py` and `independent_oracle.py`.

| Language | Port |
|---|---|
| C | [`c/f/four_square_sum_representation.c`](../../../c/f/four_square_sum_representation.c) |
| C3 | [`c3/f/four_square_sum_representation.c3`](../../../c3/f/four_square_sum_representation.c3) |
| C++ | [`cpp/f/four_square_sum_representation.cpp`](../../../cpp/f/four_square_sum_representation.cpp) |
| Elisa | [`elisa/f/four_square_sum_representation.elisa`](../../../elisa/f/four_square_sum_representation.elisa) |
| Mojo | [`mojo/f/four_square_sum_representation.mojo`](../../../mojo/f/four_square_sum_representation.mojo) |
| Nim | [`nim/f/four_square_sum_representation.nim`](../../../nim/f/four_square_sum_representation.nim) |
| Odin | [`odin/f/four_square_sum_representation.odin`](../../../odin/f/four_square_sum_representation.odin) |
| Rust | [`rust/f/four_square_sum_representation.rs`](../../../rust/f/four_square_sum_representation.rs) |
| V | [`v/f/four_square_sum_representation.v`](../../../v/f/four_square_sum_representation.v) |
| Zig | [`zig/f/four_square_sum_representation.zig`](../../../zig/f/four_square_sum_representation.zig) |

All ports and fixtures have received static source review only. No programs,
tests, builds, compilers, or benchmarks were run.
