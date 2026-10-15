# Cantor Set

This benchmark prints the levels of the middle-thirds Cantor set generated from an integer interval. The input is `[start, end, levels]`, with `0 <= start <= end <= 100000` and `0 <= levels <= 6`. Each level prints its retained intervals in left-to-right order, with endpoints formatted to six decimal places. The source's layout is preserved: two tabs before the first interval, one blank line after each expansion, and a final newline.

The implementation stores interval positions as integer ternary offsets. This matches the source's `double` interval splitting within the bounded domain and avoids platform-specific formatting differences. The output is UTF-8/ASCII bytes with a trailing NUL. Invalid input returns `-1`; insufficient output capacity returns `-2`.

| Language | Source |
|---|---|
| C | [`c/c/cantor_set.c`](../../../c/c/cantor_set.c) |
| C3 | [`c3/c/cantor_set.c3`](../../../c3/c/cantor_set.c3) |
| C++ | [`cpp/c/cantor_set.cpp`](../../../cpp/c/cantor_set.cpp) |
| Elisa | [`elisa/c/cantor_set.elisa`](../../../elisa/c/cantor_set.elisa) |
| Nim | [`nim/c/cantor_set.nim`](../../../nim/c/cantor_set.nim) |
| Odin | [`odin/c/cantor_set.odin`](../../../odin/c/cantor_set.odin) |
| Rust | [`rust/c/cantor_set.rs`](../../../rust/c/cantor_set.rs) |
| V | [`v/c/cantor_set.v`](../../../v/c/cantor_set.v) |
| Zig | [`zig/c/cantor_set.zig`](../../../zig/c/cantor_set.zig) |

## Source

- [TheAlgorithms/C `cantor_set.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/cantor_set.c)
