# Shootout strcat benchmark

The pinned Shootout `strcat.c` program repeatedly appends the six-byte string `hello\n` to a dynamically grown buffer, then prints the resulting `strlen` as decimal ASCII followed by LF. The launcher compiles with `-lm` and supplies no run options. The bounded profile uses 0 through 4,096 appends; the exported function returns the exact stdout bytes through `i64_scalar_bytes_output`.

The exported symbol is `shootout_strcat(append_count, output, output_capacity)`. Inputs outside the profile return -1. A null or undersized output buffer returns -2 without writing. The output is `6 * append_count` in base-10 followed by LF; it is at most six bytes. Implementations scan the constructed NUL-terminated string for its length, stage output before copying, and retain the source's geometric buffer-growth boundary behavior in a fixed bounded workspace.

[workload.json](workload.json) describes ordinary, growth-boundary, maximum, invalid-input, and output-buffer cases. [shootout_strcat_oracle.py](../../shootout_strcat_oracle.py) provides the exact output oracle.

For `n` appends, the bounded implementation writes and scans `O(n)` bytes and uses `O(n)` workspace. Its append-and-scan workload is retained separately from substring search and string concatenation routines with different observable work.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/shootout_strcat.c](../../../c/s/shootout_strcat.c) |
| C3 | [c3/s/shootout_strcat.c3](../../../c3/s/shootout_strcat.c3) |
| C++ | [cpp/s/shootout_strcat.cpp](../../../cpp/s/shootout_strcat.cpp) |
| Elisa | [elisa/s/shootout_strcat.elisa](../../../elisa/s/shootout_strcat.elisa) |
| Nim | [nim/s/shootout_strcat.nim](../../../nim/s/shootout_strcat.nim) |
| Odin | [odin/s/shootout_strcat.odin](../../../odin/s/shootout_strcat.odin) |
| Rust | [rust/s/shootout_strcat.rs](../../../rust/s/shootout_strcat.rs) |
| V | [v/s/shootout_strcat.v](../../../v/s/shootout_strcat.v) |
| Zig | [zig/s/shootout_strcat.zig](../../../zig/s/shootout_strcat.zig) |
| Mojo | [mojo/s/shootout_strcat.mojo](../../../mojo/s/shootout_strcat.mojo) |

## Pinned source

- [strcat.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/strcat/strcat.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/strcat/info.sh)
