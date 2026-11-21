# Strange Printer

Given a target string, the printer starts with a blank tape. Each turn writes
one chosen symbol across any contiguous interval, replacing the symbols already
there. The result is the minimum number of turns that produce the target.

This is distinct from local [Remove Boxes](../../r/remove_boxes/README.md),
which maximizes a squared removal score and carries a count of matching boxes
outside each interval. Strange Printer minimizes overwrite operations with a
two-index interval state. It is also separate from [Burst Balloons](../../b/burstballoons/README.md),
which chooses a last balloon and combines multiplication scores.

## Contract

The `i64_array_scalar` input is `[n, symbol_0, ..., symbol_(n-1)]`, with
exactly `n+1` signed 64-bit words. The bounded profile accepts `0 <= n <= 8`
and maps three symbols to integers `0..2`. The empty target returns zero.
Invalid framing, symbols outside the alphabet, and null input return `-1`.
Valid results are in `0..8`; the maximum valid frame contains nine words and
the parser also accepts up to one extra word solely to reject trailing data.

## Recurrence and references

Let `dp[left][right]` be the minimum turns for the inclusive substring. An
empty interval costs zero. The first symbol can be printed alone, giving
`dp[left+1][right] + 1`. If it matches a later position `merge`, the turn
printing that later symbol can also print the first one after the middle
substring is complete:

```text
dp[left][right] = min(
    dp[left+1][right] + 1,
    dp[left+1][merge-1] + dp[merge][right]
        for each merge > left where symbol[left] == symbol[merge]
)
```

The primary fills intervals by increasing length in `O(n^3)` time and
`O(n^2)` space. The independent reference does not use interval recurrence:
it runs breadth-first search from an all-blank tape over every possible
single-symbol interval overwrite. The bounded state space has at most `4^8`
states, including the blank marker.

The official task definition is [LeetCode 664, Strange Printer](https://leetcode.com/problems/strange-printer/).
The benchmark uses its operation as algorithm provenance only; it does not
copy code, editorial material, examples, or statement text. See
[`RIGHTS.md`](RIGHTS.md) and [`INVENTORY.md`](INVENTORY.md).

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/s/strange_printer.c`](../../../c/s/strange_printer.c) |
| C3 | [`c3/s/strange_printer.c3`](../../../c3/s/strange_printer.c3) |
| C++ | [`cpp/s/strange_printer.cpp`](../../../cpp/s/strange_printer.cpp) |
| Elisa | [`elisa/s/strange_printer.elisa`](../../../elisa/s/strange_printer.elisa) |
| Mojo | [`mojo/s/strange_printer.mojo`](../../../mojo/s/strange_printer.mojo) |
| Nim | [`nim/s/strange_printer.nim`](../../../nim/s/strange_printer.nim) |
| Odin | [`odin/s/strange_printer.odin`](../../../odin/s/strange_printer.odin) |
| Rust | [`rust/s/strange_printer.rs`](../../../rust/s/strange_printer.rs) |
| V | [`v/s/strange_printer.v`](../../../v/s/strange_printer.v) |
| Zig | [`zig/s/strange_printer.zig`](../../../zig/s/strange_printer.zig) |

The Elisa implementation collapses adjacent equal symbols before running the same interval recurrence. Each run can be contracted to one position and expanded back without changing the minimum number of turns. With at most eight runs, each interval cost fits in one byte.
