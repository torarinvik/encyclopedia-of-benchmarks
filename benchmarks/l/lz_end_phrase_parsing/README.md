# LZ-End phrase parsing

This package benchmarks the greedy LZ-End parse. At each text position, it
finds the longest **proper prefix** of the remaining suffix that is a suffix
of the already parsed text ending exactly at a previous phrase boundary. It
copies that prefix and includes the next input symbol as the phrase's trailing
symbol. If no positive-length copy is available, the phrase is one literal.
The proper-prefix condition leaves a trailing symbol in every phrase, and
sources end before the current phrase begins, so this profile does not use
overlapping copies.

Input is `[n, byte_0, ..., byte_(n-1)]`, where `0 <= n <= 64` and each symbol
is in `0..255`. The frame is exact: maximum valid length 65 words and maximum
parseable length 66 words for rejecting trailing data. The scalar result is
`133121 * phrase_count + sum(p * phrase_length_p)` for one-based phrase index
`p`. Malformed or null input returns `-1`.

The scalar records only the greedy phrase count and phrase lengths. The
definition constrains source endpoints; the profile omits the selected source
location because every equal-length valid source gives the same phrase
boundaries.
For a text of length at most 64, the checksum is at most `64 * (1+...+64) =
133120`, so multiplier 133121 keeps the phrase count separable and the result
below 8,652,864.

This is distinct from the suite's LZ77 profiles, which can use a prior match
ending at any position and include overlap behavior, and from LZ78/LZW, which
build dictionary phrases. LZ-End's defining source-boundary restriction is
the subject of Kreft and Navarro's [2010 paper](https://doi.org/10.1109/DCC.2010.29)
and their [2013 journal article](https://doi.org/10.1016/j.tcs.2012.02.006).
The implementations use bounded direct scans and make no claim to reproduce
the paper's suffix-array/BWT parser or its asymptotic construction time.

The primary reference searches candidate copy lengths from longest to
shortest against prior phrase boundaries. The independent reference enumerates
every legal source boundary and candidate length, then takes the maximum
directly. Their bounded worst-case time is O(n^4) and auxiliary space is O(n).

Language ports: [C](../../../c/l/lz_end_phrase_parsing.c),
[C3](../../../c3/l/lz_end_phrase_parsing.c3),
[C++](../../../cpp/l/lz_end_phrase_parsing.cpp),
[Elisa](../../../elisa/l/lz_end_phrase_parsing.elisa),
[Mojo](../../../mojo/l/lz_end_phrase_parsing.mojo),
[Nim](../../../nim/l/lz_end_phrase_parsing.nim),
[Odin](../../../odin/l/lz_end_phrase_parsing.odin),
[Rust](../../../rust/l/lz_end_phrase_parsing.rs),
[V](../../../v/l/lz_end_phrase_parsing.v), and
[Zig](../../../zig/l/lz_end_phrase_parsing.zig).

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run while preparing this package.
