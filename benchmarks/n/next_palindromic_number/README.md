# Next palindromic number

Return the least nonnegative base-10 palindromic integer strictly greater than
the supplied integer. The primary implementation mirrors the decimal prefix;
when that candidate is not greater, it increments the prefix with carry and
mirrors again. Carry beyond an all-nine prefix grows the digit width and
produces `1` followed by zeroes and a final `1`.

## Contract

The `i64_array_scalar` input is exactly `[n]`, with
`0 <= n <= 9,999,999,999,999,999`. `n` uses its ordinary decimal notation
without leading zeroes. The result is the smallest integer `p > n` whose
decimal representation reads identically in both directions. Invalid frames
and out-of-range values return `-1`.

The largest valid input is sixteen nines; its successor is the 17-digit value
`10,000,000,000,000,001`, which fits signed i64. Each port uses a fixed
17-digit buffer and O(d) digit work for `d <= 16`.

The null input pointer is invalid independently of an empty non-null frame;
both ABI cases are pinned in the workload. Local [`palindrome_number`](../p/palindrome_number/README.md)
and [`valid_palindrome`](../v/valid_palindrome/README.md) predicates only
recognize palindromes, while this package finds the next strictly greater
decimal palindrome. [`shortest_palindrome`](../s/shortest_palindrome/README.md)
and [`palindrome_partitioning`](../p/palindrome_partitioning/README.md)
transform strings and use different operations.

## References and workload

The primary reference performs half-mirroring and prefix carry. The
independent reference binary-searches the half-prefix range separately for
each feasible digit width. The workload uses independently authored boundary,
carry, already-palindromic, malformed, and maximum-width cases; see
[`workload.json`](workload.json).

The public Codewars title is a discovery lead only. Algorithm provenance is
the general numeric-palindrome and increasing-generation description in
[Generating palindromic numbers](https://rhyscitlema.estenligne.com/algorithms/generating-palindromic-numbers/).
See [`RIGHTS.md`](RIGHTS.md) for the provenance and reuse boundary.

## Implementations

| Language | Source |
|---|---|
| C | [`c/n/next_palindromic_number.c`](../../../c/n/next_palindromic_number.c) |
| C3 | [`c3/n/next_palindromic_number.c3`](../../../c3/n/next_palindromic_number.c3) |
| C++ | [`cpp/n/next_palindromic_number.cpp`](../../../cpp/n/next_palindromic_number.cpp) |
| Elisa | [`elisa/n/next_palindromic_number.elisa`](../../../elisa/n/next_palindromic_number.elisa) |
| Mojo | [`mojo/n/next_palindromic_number.mojo`](../../../mojo/n/next_palindromic_number.mojo) |
| Nim | [`nim/n/next_palindromic_number.nim`](../../../nim/n/next_palindromic_number.nim) |
| Odin | [`odin/n/next_palindromic_number.odin`](../../../odin/n/next_palindromic_number.odin) |
| Rust | [`rust/n/next_palindromic_number.rs`](../../../rust/n/next_palindromic_number.rs) |
| V | [`v/n/next_palindromic_number.v`](../../../v/n/next_palindromic_number.v) |
| Zig | [`zig/n/next_palindromic_number.zig`](../../../zig/n/next_palindromic_number.zig) |

The package-local static checker is [`check_inventory.py`](check_inventory.py);
the reference/workload validator is [`verify_workload.py`](verify_workload.py).
