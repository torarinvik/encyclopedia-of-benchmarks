# Set puzzle: find all sets in a supplied hand

Count and return every valid three-card set in a deterministic hand. The
measured kernel receives the hand directly: it does not shuffle a deck, deal a
random subset, retry until a target count appears, or simulate a game.

## Contract

The `i64_array_bytes_output` input is `[n, card0, ..., card(n-1)]`, with
`0 <= n <= 12`, exactly `n + 1` words, and unique card codes in `[0,80]`.
Each code is `d0 + 3*d1 + 9*d2 + 27*d3`. The four base-3 digits independently
encode the card's attributes, each taking a value from 0 through 2. For a triple of
cards to form a set, every attribute must be either equal across all three
cards or take all three values. Equivalently, each of the four digit sums is
zero modulo three.

The result is `[set_count, i0, j0, k0, i1, j1, k1, ...]`, encoded as
little-endian signed-i64 words. Each triple contains zero-based input indices
`i < j < k`; triples are ordered lexicographically. Duplicate card codes,
codes outside the deck, malformed frames, or an input length outside the
profile return `-1`. A null output or insufficient capacity returns `-2`.
Errors write no output.

For a pair of cards, the unique third card is the coordinatewise negative of
their sum modulo three. The primary port stores each input code's index in an
81-entry direct table, then checks every unordered pair. It emits a triple
only when the complement's index follows both pair indices, so each set is
listed once. The work is `O(n^2)` and fixed workspace is 93 bytes: the 81-byte
code-to-index table and twelve one-byte card codes retained for the output
pass.

At most `C(12,2)/3 = 22` sets can occur: each set consumes three different
unordered pairs, and each pair has at most one complement in a unique-card
hand. The maximum result is therefore 67 words, or 536 bytes. The cap is a
proven upper bound for the profile; a workload fixture need not attain it.

## Algorithm and distinction

This is a deterministic set-enumeration operation over a supplied hand. The
RosettaGit task also describes dealing cards and selecting hands by their set
count; those random deal and retry steps are outside this benchmark. The
local [`set_algebra`](../set_algebra/README.md) performs membership and binary
set operations, [`association`](../../a/association/README.md) mines frequent
itemsets, and [`subset_combinations`](../subset_combinations/README.md)
enumerates generic fixed-size index selections. None uses the four-attribute
modulo-three complement relation to find all Set triples.

The task title and high-level operation come from the RosettaGit [Set puzzle
page](https://rosettagit.org/tasks/set-puzzle/). The integer encoding,
complement lookup contract, deterministic ordering, bounds, workload, and
implementations are original. No task code, prose, examples, or tests are
copied.

## Workload and references

[`workload.json`](workload.json) includes original 9-card/4-set and
12-card/6-set hands, an empty hand, a hand with no set, malformed frames,
duplicate and out-of-range codes, null pointers, and output capacity limits.
[`primary_oracle.py`](primary_oracle.py) uses the complement index table.
[`independent_oracle.py`](independent_oracle.py) examines every unordered
triple and checks the four attribute columns directly. The package-local
`verify_workload.py` and `check_inventory.py` are static helpers and were not
run.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/set_puzzle_find_sets.c`](../../../c/s/set_puzzle_find_sets.c) |
| C3 | [`c3/set_puzzle_find_sets.c3`](../../../c3/s/set_puzzle_find_sets.c3) |
| C++ | [`cpp/set_puzzle_find_sets.cpp`](../../../cpp/s/set_puzzle_find_sets.cpp) |
| Elisa | [`elisa/set_puzzle_find_sets.elisa`](../../../elisa/s/set_puzzle_find_sets.elisa) |
| Mojo | [`mojo/set_puzzle_find_sets.mojo`](../../../mojo/s/set_puzzle_find_sets.mojo) |
| Nim | [`nim/set_puzzle_find_sets.nim`](../../../nim/s/set_puzzle_find_sets.nim) |
| Odin | [`odin/set_puzzle_find_sets.odin`](../../../odin/s/set_puzzle_find_sets.odin) |
| Rust | [`rust/set_puzzle_find_sets.rs`](../../../rust/s/set_puzzle_find_sets.rs) |
| V | [`v/set_puzzle_find_sets.v`](../../../v/s/set_puzzle_find_sets.v) |
| Zig | [`zig/set_puzzle_find_sets.zig`](../../../zig/s/set_puzzle_find_sets.zig) |
