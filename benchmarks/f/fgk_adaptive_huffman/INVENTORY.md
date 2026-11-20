# Static inventory

Package `fgk_adaptive_huffman` exports `fgk_adaptive_huffman` with ABI
`i64_array_bytes_output`. Input is `[n, symbols...]`, with `n<=64` and a fixed
alphabet of 16 byte-valued symbol IDs. Valid/parser bounds are 65/66 i64 words.
Output is a u64le bit count followed by MSB-first packed code bits, at most 160
bytes. Invalid input is `-1`; output failure is `-2`; workspace is 4096 bytes.

Method: one NYT leaf represents unseen symbols. For a symbol, emit its current
path (and a four-bit ID if new), then interchange with the highest eligible
equal-weight node and increment toward the root while preserving the sibling
property. The independent reference uses object nodes and direct block scans.
Source: NIST DADS FGK entry and Knuth, *Dynamic Huffman Coding* (1985), DOI
10.1016/0196-6774(85)90036-7.

Each row points to a shared language source that exports both this profile and
Vitter Algorithm A using separate update functions.

| Language | Source |
|---|---|
| C | [`c/a/adaptive_huffman_pair.c`](../../../c/a/adaptive_huffman_pair.c) |
| C3 | [`c3/a/adaptive_huffman_pair.c3`](../../../c3/a/adaptive_huffman_pair.c3) |
| C++ | [`cpp/a/adaptive_huffman_pair.cpp`](../../../cpp/a/adaptive_huffman_pair.cpp) |
| Elisa | [`elisa/a/adaptive_huffman_pair.elisa`](../../../elisa/a/adaptive_huffman_pair.elisa) |
| Mojo | [`mojo/a/adaptive_huffman_pair.mojo`](../../../mojo/a/adaptive_huffman_pair.mojo) |
| Nim | [`nim/a/adaptive_huffman_pair.nim`](../../../nim/a/adaptive_huffman_pair.nim) |
| Odin | [`odin/a/adaptive_huffman_pair.odin`](../../../odin/a/adaptive_huffman_pair.odin) |
| Rust | [`rust/a/adaptive_huffman_pair.rs`](../../../rust/a/adaptive_huffman_pair.rs) |
| V | [`v/a/adaptive_huffman_pair.v`](../../../v/a/adaptive_huffman_pair.v) |
| Zig | [`zig/a/adaptive_huffman_pair.zig`](../../../zig/a/adaptive_huffman_pair.zig) |

Static inventory only; no program or checker has been run.
