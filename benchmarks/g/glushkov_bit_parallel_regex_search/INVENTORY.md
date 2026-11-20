# Source inventory

| Language | Source |
|---|---|
| C | `c/g/glushkov_bit_parallel_regex_search.c` |
| C3 | `c3/g/glushkov_bit_parallel_regex_search.c3` |
| C++ | `cpp/g/glushkov_bit_parallel_regex_search.cpp` |
| Elisa | `elisa/g/glushkov_bit_parallel_regex_search.elisa` |
| Mojo | `mojo/g/glushkov_bit_parallel_regex_search.mojo` |
| Nim | `nim/g/glushkov_bit_parallel_regex_search.nim` |
| Odin | `odin/g/glushkov_bit_parallel_regex_search.odin` |
| Rust | `rust/g/glushkov_bit_parallel_regex_search.rs` |
| V | `v/g/glushkov_bit_parallel_regex_search.v` |
| Zig | `zig/g/glushkov_bit_parallel_regex_search.zig` |

The fixed bounds are 24 text bytes, 32 pattern bytes, eight consuming
positions, 64 syntax nodes, and nine automaton states. Output is at most 24
bytes and algorithm workspace is at most 8,192 bytes. The package does not
allocate dynamically.
