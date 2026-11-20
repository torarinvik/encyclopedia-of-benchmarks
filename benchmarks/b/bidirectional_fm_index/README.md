# Bidirectional FM-index extension

This bounded profile maintains a pattern's suffix-array interval in both a text and its reversal, so successive exact-search steps can extend the pattern at either end. It uses a small four-symbol alphabet and a unique terminator to make the interval transitions explicit.

The primary builds BWT indexes for `text+[0]` and `reverse(text)+[0]`. An interval `[l,r)` identifies suffixes prefixed by the current pattern in the forward index and by its reversal in the reverse index. Prepending a symbol uses ordinary backward search in the forward BWT, then transfers the matching subinterval to the reverse index by counting smaller symbols in the parent BWT interval. Appending uses the symmetric reverse-index update. Occurrence rank uses bounded scans over the BWT columns. This is the synchronized forward/backward search mechanism described by Lam et al.'s [bi-directional BWT paper](https://doi.org/10.1109/BIBM.2009.42) ([author-hosted record and paper](https://hub.hku.hk/handle/10722/129577)).

The exact input is `[N,Q,text_symbols...,(side,symbol)*Q]`. Text and operation counts are 0–64; text and operation symbols are 1–4. Side 0 prepends its symbol; side 1 appends it. After each operation, the package adds the one-based operation index times the number of overlapping occurrences of the current pattern. Invalid input returns `-1`. The independent verifier materializes each pattern and scans every possible text offset directly.

This package benchmarks exact bidirectional interval extension. It does not implement mismatch enumeration or approximate read alignment, suffix-array locating, compressed rank structures, or the papers' compressed-space guarantees. Suffix arrays use a bounded direct comparison sort; the profile makes no construction-time claim for large texts.

## Language ports

- [C](../../../c/b/bidirectional_fm_index.c)
- [C3](../../../c3/b/bidirectional_fm_index.c3)
- [C++](../../../cpp/b/bidirectional_fm_index.cpp)
- [Elisa](../../../elisa/b/bidirectional_fm_index.elisa)
- [Mojo](../../../mojo/b/bidirectional_fm_index.mojo)
- [Nim](../../../nim/b/bidirectional_fm_index.nim)
- [Odin](../../../odin/b/bidirectional_fm_index.odin)
- [Rust](../../../rust/b/bidirectional_fm_index.rs)
- [V](../../../v/b/bidirectional_fm_index.v)
- [Zig](../../../zig/b/bidirectional_fm_index.zig)

The [workload](workload.json), [primary paired-index oracle](primary_oracle.py), [independent direct-scan verifier oracle](independent_oracle.py), and [static inventory](verify_workload.py) describe and review the package without executing a language port.
