# Hofstadter Figure–Figure sequences

This package generates matching prefixes of the Figure sequence `F` and the
complementary Space sequence `S`. The sequence is unrelated to the Hofstadter
Q recurrence: each new Figure term is the sum of the prior pair, while each
Space term is the next positive integer not used by the Figure sequence.

## Bounded profile

The exported `hofstadter_figure_figure_sequences` function uses the
`i64_array_bytes_output` ABI. Input is one signed 64-bit integer `n`, with
`1 <= n <= 64`. Output is `[n, F_1, ..., F_n, S_1, ..., S_n]` as
little-endian signed 64-bit words, at most 1,032 bytes. Fixed workspace is at
most 4,096 bytes. The maximum parseable frame contains two words; a trailing
word is rejected because the valid input contains exactly one.

The clean-room recurrence starts with `F_1=1`, `S_1=2`. For each later index,
it sets `F_i=F_(i-1)+S_(i-1)`, then chooses `S_i` as the smallest integer
strictly greater than `S_(i-1)` that does not occur in `F_1,...,F_i`. This
incremental complement search is finite and deterministic. The ports use a
linear scan of the known Figure prefix for each candidate, giving `O(n^3)`
worst-case time and `O(n)` fixed storage for the bounded `n<=64` profile.
Invalid input returns `-1`; a null output or short capacity returns `-2`.
Errors leave the output untouched.

All arithmetic is signed 64-bit. For `i<=64`, at most `i` known Figure terms
can be skipped while selecting `S_i`, giving the conservative bound
`S_i <= 2 + sum(k+1, k=2..i) <= 2,144`. Consequently each Figure term is at
most `1 + 63*2,144 = 135,073`; candidates, sums, and output sizing stay far
inside the signed 64-bit range.

The first terms are `F = 1, 3, 7, 12, 18, 26, ...` and
`S = 2, 4, 5, 6, 8, 9, ...`. Jubin describes these as the lexicographically
minimal partition construction whose second set consists of first differences
of the first set; the bounded profile computes the paired terms directly.
See [RIGHTS.md](RIGHTS.md) for provenance. The output includes both complete
prefixes, so the result preserves the pair rather than only one sequence.

[`primary_oracle.py`](primary_oracle.py) follows the incremental recurrence.
[`independent_oracle.py`](independent_oracle.py) checks the additive relation,
complement minimality, and disjointness as properties of the returned prefix.
[`workload.json`](workload.json) provides deterministic fixtures and ABI error
cases. The inventory lists all ten source ports.
