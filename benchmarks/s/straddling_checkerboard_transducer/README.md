# Straddling checkerboard transducer

This benchmark encodes and decodes a caller-supplied three-row decimal checkerboard. The two empty cells in the top row identify the row digits for rows one and two. Top-row symbols therefore use one digit, while lower-row symbols use a row digit followed by a column digit.

## Contract

- ABI: `i64_array_bytes_output`. Input is `[mode,board[30],text_length,text_bytes[text_length]]`.
- `mode=0` encodes; `mode=1` decodes. `0 <= text_length <= 64`; the exact frame length is `32 + text_length`, at most 96 signed 64-bit values. A 97-value frame is the largest parsed malformed frame.
- The board is stored row-major as three rows of ten cells. Exactly two cells in row zero contain `0`; these holes' column digits are the row indicators for rows one and two. The remaining 28 cells contain distinct printable ASCII bytes from 32 through 126. Lower rows have no holes.
- Encoding accepts the 28 nonzero board symbols and emits ASCII decimal digit bytes. NUL is the hole marker and is never an encodable symbol. A symbol in row zero emits its column digit. A symbol in either lower row emits the corresponding top-hole column digit followed by its column digit.
- Decoding accepts only ASCII digits `0` through `9`. A digit for a nonempty top-row cell emits that symbol. A top-row hole digit consumes the next digit and selects that column in the indicated lower row. A dangling hole digit, non-digit, or malformed board is invalid.
- Output is the raw byte stream, with no terminator. Encoding emits at most 128 bytes and decoding at most 64. Malformed input returns `-1`; null or undersized output returns `-2` after complete input validation. Errors leave output untouched. A valid empty operation still requires a non-null output pointer, though capacity zero is sufficient.

## Method and bounds

The primary port uses direct row/column lookup and consumes one or two digits according to whether the first digit names a top-row hole. The independent reference builds each symbol's codeword and decodes with a prefix trie. The two empty cells make the code prefix-free: no top-row one-digit code begins with a row indicator.

For a text of length `n <= 64`, the reference board validator takes `O(28^2)` comparisons to reject duplicate symbols. The Elisa port tracks the 95 printable ASCII values in two 64-bit masks and checks each board cell once. Encoding uses a bounded scan of 30 board cells per symbol, and decoding visits each digit once, so both are `O(n)` for this fixed-size board. Scratch is `O(1)` fixed storage apart from the Elisa port's 128-byte staged output; total declared workspace is bounded by 256 bytes, excluding caller-owned input/output memory. The workload includes a 64-symbol lower-row encoding that reaches 128 output bytes and a capacity-127 probe that must fail without writing output.

## Sources and rights

Esslinger (editor), *Learning and Experiencing Cryptography with CrypTool and SageMath*, edition 12 (2018), §2.2.1, pp. 33–34, gives the method context: a 3×10 grid, two top-row holes used as lower-row indicators, and one- or two-digit codes. The CrypTool book's front matter permits free distribution with attribution to the authors, title, and CrypTool website, and additionally applies GNU Free Documentation License 1.3 or later. This package uses only the algorithm idea; no book text, code, tables, examples, exercise data, or figures were copied.

The pinned [RosettaCodeData popular-task title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) supplied the score-9 title as discovery only. No Rosetta task page, solution, prose, code, examples, or fixtures were consulted or reused.

## Package files

- [`workload.json`](workload.json): contract metadata, provenance, and bounded fixtures.
- [`primary_oracle.py`](primary_oracle.py): direct table lookup and indicator-based decode.
- [`independent_oracle.py`](independent_oracle.py): codeword mapping and prefix-trie decode.
- [`verify_workload.py`](verify_workload.py): source-level framing and dual-reference reconciler; not run.
- [`check_inventory.py`](check_inventory.py): static package and source inventory checker; not run.
- [`INVENTORY.json`](INVENTORY.json) and [`INVENTORY.md`](INVENTORY.md): package artifact map.
- [`RIGHTS.md`](RIGHTS.md): clean-room and provenance note.

## Native ports

| Language | Source |
|---|---|
| C | [`c/s/straddling_checkerboard_transducer.c`](../../../c/s/straddling_checkerboard_transducer.c) |
| C3 | [`c3/s/straddling_checkerboard_transducer.c3`](../../../c3/s/straddling_checkerboard_transducer.c3) |
| C++ | [`cpp/s/straddling_checkerboard_transducer.cpp`](../../../cpp/s/straddling_checkerboard_transducer.cpp) |
| Elisa | [`elisa/s/straddling_checkerboard_transducer.elisa`](../../../elisa/s/straddling_checkerboard_transducer.elisa) |
| Mojo | [`mojo/s/straddling_checkerboard_transducer.mojo`](../../../mojo/s/straddling_checkerboard_transducer.mojo) |
| Nim | [`nim/s/straddling_checkerboard_transducer.nim`](../../../nim/s/straddling_checkerboard_transducer.nim) |
| Odin | [`odin/s/straddling_checkerboard_transducer.odin`](../../../odin/s/straddling_checkerboard_transducer.odin) |
| Rust | [`rust/s/straddling_checkerboard_transducer.rs`](../../../rust/s/straddling_checkerboard_transducer.rs) |
| V | [`v/s/straddling_checkerboard_transducer.v`](../../../v/s/straddling_checkerboard_transducer.v) |
| Zig | [`zig/s/straddling_checkerboard_transducer.zig`](../../../zig/s/straddling_checkerboard_transducer.zig) |
