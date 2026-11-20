# HsaDelta differential compression

This package benchmarks the fixed-block-size HsaDelta method for encoding a
version byte string as insert and copy commands relative to a reference byte
string. It is a bounded clean-room profile.

## Contract

- ABI: `i64_array_bytes_output`; input is
  `[reference_length, version_length, block_size, reference_bytes..., version_bytes...]`.
- Reference and version lengths are each at most 32 bytes; block size is 2 to
  4; bytes are in `0..255`. The exact frame has `3+m+n` words; 68 words are
  parseable for trailing-frame rejection.
- Complete reference blocks start at `0,p,2p,...`; an incomplete tail is not
  hashed. The primary uses a lexicographic suffix array over fixed-width
  polynomial block fingerprints, binary-searches the query prefix interval,
  checks the best block depth and the immediately shorter depth, then extends
  matching bytes left and right.
- The fixed-width base-257 fingerprint encodes each `byte+1` digit. With
  `p<=4`, it is collision-free and fits signed i64. This deterministic bounded
  choice replaces the paper's 61-bit Rabin–Karp fingerprint.
- Search considers the next `p` version offsets together. It selects the
  longest extended match, with ties going to the earlier target start and then
  earlier reference start. A gap becomes one INSERT; the match becomes one
  COPY; the final unmatched suffix becomes one INSERT.
- Output has no count prefix. INSERT is `(0, length, byte_as_i64...)`; COPY is
  `(1, reference_offset, length)`. Each word is serialized as little-endian
  signed 64-bit. Empty version input produces an empty output. Invalid input
  returns `-1`; null or undersized output returns `-2` without writes.

The profile uses only the fixed-block-size variant. The paper's second variant,
which grows block size proportionally with reference size to hold a fixed number
of blocks, is excluded. The quick-index filter, pointer array, and packed
block-hash table are also excluded as lookup accelerators; the bounded primary
uses direct suffix-array prefix bounds instead. Its bounded construction makes
no claim to the paper's large-file time or space bounds.

The independent oracle checks every block-aligned reference position directly,
without fingerprints or suffix arrays. It uses the same output contract and
tie rules but a different matching search.

## Sources and rights

The official [NIST DADS HsaDelta entry](https://xlinux.nist.gov/dads/HTML/hsadelta.html)
describes hashing reference blocks, building a suffix array and lookup
structures, finding longest matches, and emitting insert/copy commands. The
primary method reference is Ramesh C. Agarwal, Karan Gupta, Shaili Jain, and
Suchitra Amalapurapu, “An approximation to the greedy algorithm for
differential compression,” *IBM Journal of Research and Development* 50(1),
149–166 (2006), [DOI 10.1147/rd.501.0149](https://doi.org/10.1147/rd.501.0149).
Only method descriptions and attribution are used; no source code, examples,
tests, figures, or prose are copied. See [RIGHTS.md](RIGHTS.md).

[`workload.json`](workload.json) covers empty output, inserts, copies, block
sizes, left extension, source ties, maximum lengths, malformed input, and
output-buffer errors. `verify_workload.py` compares the hand-authored fixture
outputs with both Python references. [`INVENTORY.md`](INVENTORY.md) records
the static port inventory and ABI details; `check_inventory.py` provides a
static inventory check.

| Language | Source |
|---|---|
| C | [`c/h/hsadelta_differential_compression.c`](../../../c/h/hsadelta_differential_compression.c) |
| C3 | [`c3/h/hsadelta_differential_compression.c3`](../../../c3/h/hsadelta_differential_compression.c3) |
| C++ | [`cpp/h/hsadelta_differential_compression.cpp`](../../../cpp/h/hsadelta_differential_compression.cpp) |
| Elisa | [`elisa/h/hsadelta_differential_compression.elisa`](../../../elisa/h/hsadelta_differential_compression.elisa) |
| Mojo | [`mojo/h/hsadelta_differential_compression.mojo`](../../../mojo/h/hsadelta_differential_compression.mojo) |
| Nim | [`nim/h/hsadelta_differential_compression.nim`](../../../nim/h/hsadelta_differential_compression.nim) |
| Odin | [`odin/h/hsadelta_differential_compression.odin`](../../../odin/h/hsadelta_differential_compression.odin) |
| Rust | [`rust/h/hsadelta_differential_compression.rs`](../../../rust/h/hsadelta_differential_compression.rs) |
| V | [`v/h/hsadelta_differential_compression.v`](../../../v/h/hsadelta_differential_compression.v) |
| Zig | [`zig/h/hsadelta_differential_compression.zig`](../../../zig/h/hsadelta_differential_compression.zig) |
