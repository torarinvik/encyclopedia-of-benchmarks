# BLR linearity test

This package implements the Blum–Luby–Rubinfeld linearity (homomorphism) test
for Boolean functions on `GF(2)^n`, as listed in *Encyclopedia of Algorithms*
Chapter 202, “Linearity Testing/Testing Hadamard Codes.” A trial chooses
independent uniform vectors `x` and `y`, queries `f(x)`, `f(y)`, and
`f(x xor y)`, and rejects if `f(x) xor f(y) != f(x xor y)`.

## Bounded contract

- ABI: `i64_array_bytes_output`; symbol `blr_linearity_test`.
- Input: `[n,q,f(0),...,f(2^n-1),x0,y0,...,x(q-1),y(q-1)]`.
- `1<=n<=6`, `1<=q<=32`. Truth-table index is the integer representation of a
  vector, with coordinate 0 in the least significant bit; each table entry is
  `0` or `1`. Each supplied pair is an integer in `[0,2^n)` and stands for one
  independent uniform random choice made by the source algorithm.
- Pairs are processed in order and the test halts at its first failed
  consistency check. Output is `[accept_bit,rounds_executed,query_calls]`,
  where each executed round counts exactly three oracle calls, including when
  two or more query points coincide. All `q` rounds pass for acceptance; a
  failure reports the number through and including the first failing round.
- The pair tape fixes randomness for replay. Since callers may provide any
  tape and `q` is not derived from an epsilon parameter, this profile makes no
  soundness or query-complexity guarantee.
- Maximum input is 130 signed-i64 words; output is three little-endian signed
  i64 words (24 bytes). Invalid input returns `-1`; null or short output
  returns `-2`, without writing bytes. Workspace is bounded to 1,024 bytes.

This differs from the repository's exact
[`system_of_linear_equations_mod_2`](../../s/system_of_linear_equations_mod_2/README.md),
which solves a supplied linear system, and its
[`fast_walsh_hadamard_transform`](../../f/fast_walsh_hadamard_transform/README.md),
which transforms a vector. Neither queries a Boolean-function oracle at the
three BLR points or checks the homomorphism identity.

The primary oracle stops during the source-ordered tape scan at the first
failure. The independent oracle builds the complete per-round violation trace
then selects its first set bit, providing a separately structured reference
for the reported stopping point and query count.

## Source and rights

Primary attribution: Manuel Blum, Michael Luby, and Ronitt Rubinfeld,
“Self-testing/correcting with applications to numerical problems,” *Journal
of Computer and System Sciences* 47(3), 1993, DOI
[10.1016/0022-0000(93)90044-W](https://doi.org/10.1016/0022-0000(93)90044-W).
The encyclopedia entry is [Chapter 202](https://doi.org/10.1007/978-1-4939-2864-4_202).
The three-query rule is also stated in the parity-encoding section of the
Arora–Lund–Motwani–Sudan–Szegedy paper, “Proof Verification and the Hardness
of Approximation Problems” ([paper](https://madhu.seas.harvard.edu/papers/1992/almss-journ.pdf),
Section 4). These works are used for mathematical attribution and algorithm
semantics only. All ports, fixtures, and documentation here are clean-room;
no code, examples, figures, or protected prose were copied. See
[`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary oracle](primary_oracle.py)
- [independent oracle](independent_oracle.py)
- [`INVENTORY.md`](INVENTORY.md), [`inventory.json`](inventory.json), and [static inventory checker](check_inventory.py)

| Language | Port |
|---|---|
| C | [`c/b/blr_linearity_test.c`](../../../c/b/blr_linearity_test.c) |
| C3 | [`c3/b/blr_linearity_test.c3`](../../../c3/b/blr_linearity_test.c3) |
| C++ | [`cpp/b/blr_linearity_test.cpp`](../../../cpp/b/blr_linearity_test.cpp) |
| Elisa | [`elisa/b/blr_linearity_test.elisa`](../../../elisa/b/blr_linearity_test.elisa) |
| Mojo | [`mojo/b/blr_linearity_test.mojo`](../../../mojo/b/blr_linearity_test.mojo) |
| Nim | [`nim/b/blr_linearity_test.nim`](../../../nim/b/blr_linearity_test.nim) |
| Odin | [`odin/b/blr_linearity_test.odin`](../../../odin/b/blr_linearity_test.odin) |
| Rust | [`rust/b/blr_linearity_test.rs`](../../../rust/b/blr_linearity_test.rs) |
| V | [`v/b/blr_linearity_test.v`](../../../v/b/blr_linearity_test.v) |
| Zig | [`zig/b/blr_linearity_test.zig`](../../../zig/b/blr_linearity_test.zig) |

The ten package ports are registered in the `i64_array_bytes_output` suite and
catalog. No programs,
tests, scripts, checkers, builds, compilers, profilers, or benchmarks were run.
