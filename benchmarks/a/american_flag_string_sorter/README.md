# American flag string sorter

Input is `[n,(length,byte...)*n]` for up to 256 byte strings, each at most 32
bytes. Sort them lexicographically, with the end-of-string sentinel ordered
before every byte. Invalid framing or values return `-1`.

The implementation uses American flag MSD distribution. At each byte position
it counts 257 keys (end marker plus the 256 byte values), computes each bucket's
range, and cyclically permutes string indices into those ranges in place. It
then recurses on nonempty byte buckets. This is distinct from the stable,
buffered MSD string sorter: this profile uses in-place bucket cycles and does
not preserve an order among equal strings.

The return value is an order-sensitive checksum. For each sorted string at
one-based rank `r`, add `r * (length + 1 + sum(byte + 1))`. The primary performs
the in-place American flag partition; the independent reference uses a
comparison sort. Worst-case time is `O(R * n * L)` for radix `R=257`, at most
`n=256` strings, and maximum length `L=32`; auxiliary space is `O(n + R*L)`.

The algorithm idea is described in the [NIST Dictionary of Algorithms and Data
Structures](https://xlinux.nist.gov/dads/HTML/americanFlagSort.html), which
also cites McIlroy, Bostic, and McIlroy's *Engineering Radix Sort* (1993). The
package is independently authored; see [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/a/american_flag_string_sorter.c](../../../c/a/american_flag_string_sorter.c) |
| C3 | [c3/a/american_flag_string_sorter.c3](../../../c3/a/american_flag_string_sorter.c3) |
| C++ | [cpp/a/american_flag_string_sorter.cpp](../../../cpp/a/american_flag_string_sorter.cpp) |
| Elisa | [elisa/a/american_flag_string_sorter.elisa](../../../elisa/a/american_flag_string_sorter.elisa) |
| Mojo | [mojo/a/american_flag_string_sorter.mojo](../../../mojo/a/american_flag_string_sorter.mojo) |
| Nim | [nim/a/american_flag_string_sorter.nim](../../../nim/a/american_flag_string_sorter.nim) |
| Odin | [odin/a/american_flag_string_sorter.odin](../../../odin/a/american_flag_string_sorter.odin) |
| Rust | [rust/a/american_flag_string_sorter.rs](../../../rust/a/american_flag_string_sorter.rs) |
| V | [v/a/american_flag_string_sorter.v](../../../v/a/american_flag_string_sorter.v) |
| Zig | [zig/a/american_flag_string_sorter.zig](../../../zig/a/american_flag_string_sorter.zig) |
