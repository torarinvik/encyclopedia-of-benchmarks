# Main–Lorentz tandem repetitions

Given a bounded byte alphabet string, enumerate every tandem square: an
interval containing two equal adjacent blocks. Results are returned in
increasing start position and then increasing half-length.

This package benchmarks the Main–Lorentz divide-and-conquer method. At each
split, Z values compare reversed halves and cross-boundary strings. Each
center and pair of matching extensions describes a group of crossing squares;
the implementation expands those groups into interval marks. The independent
oracle scans each possible start and period and directly compares the two
blocks. This differs from
[`approximate_tandem_squares`](../../a/approximate_tandem_squares/README.md),
which uses direct mismatch scanning, and
[`runenumerate`](../../r/runenumerate/README.md), which reports maximal
periodic runs instead of all tandem squares.

## Bounded contract

The `i64_array_bytes_output` entry point is
`main_lorentz_tandem_repetitions(input, length, output, capacity)`. Input is
`[N, symbol_0, ..., symbol_(N-1)]`, with `0<=N<=24` and symbols in `[0,255]`.
The official algorithm has no single standard input contract; this workload
uses a small fixed alphabet and bounds the complete list of square intervals.

Output is a little-endian signed 64-bit word array. The first word is the
number of repetitions. Each remaining word packs one result as
`start*32 + half_length`, ordered by start and then half-length. Success returns
`8*(1+count)` bytes. Malformed input returns `-1`; a null or undersized output
returns `-2`; errors leave output unchanged. The maximum input length is 25
words, the maximum number of repetitions is 144, the maximum output is 1160
bytes, and fixed workspace is 16384 bytes.

The divide-and-conquer search computes Z arrays in `O(N log N)` work across
the recursion. Expanding all reported squares and canonicalizing their order
costs `O(N^2)` in the bounded profile, matching the possible quadratic output
size. The direct oracle compares each candidate block pair and takes
`O(N^3)` in the worst case.

[`workload.json`](workload.json) records the fixtures and ABI. The primary and
independent oracle files describe the two different algorithms.
[`verify_workload.py`](verify_workload.py) checks fixture/oracle agreement,
provenance, and the ten source paths; it is included for later review and has
not been run.

## Provenance and rights

The algorithm candidate and its Main–Lorentz / Z-function structure were
discovered in OI Wiki's
[Main–Lorentz article](https://oi-wiki.org/string/main-lorentz/). That page
lists CC BY-SA 4.0 and SATA terms. The package uses the algorithm description
for discovery and attribution; its bounded interface, workload, fixtures,
oracles, prose, and implementations are clean-room work. No upstream source
code or article prose was copied. See [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/p/main_lorentz_tandem_repetitions.c`](../../../c/p/main_lorentz_tandem_repetitions.c) |
| C3 | [`c3/p/main_lorentz_tandem_repetitions.c3`](../../../c3/p/main_lorentz_tandem_repetitions.c3) |
| C++ | [`cpp/p/main_lorentz_tandem_repetitions.cpp`](../../../cpp/p/main_lorentz_tandem_repetitions.cpp) |
| Elisa | [`elisa/p/main_lorentz_tandem_repetitions.elisa`](../../../elisa/p/main_lorentz_tandem_repetitions.elisa) |
| Mojo | [`mojo/p/main_lorentz_tandem_repetitions.mojo`](../../../mojo/p/main_lorentz_tandem_repetitions.mojo) |
| Nim | [`nim/p/main_lorentz_tandem_repetitions.nim`](../../../nim/p/main_lorentz_tandem_repetitions.nim) |
| Odin | [`odin/p/main_lorentz_tandem_repetitions.odin`](../../../odin/p/main_lorentz_tandem_repetitions.odin) |
| Rust | [`rust/p/main_lorentz_tandem_repetitions.rs`](../../../rust/p/main_lorentz_tandem_repetitions.rs) |
| V | [`v/p/main_lorentz_tandem_repetitions.v`](../../../v/p/main_lorentz_tandem_repetitions.v) |
| Zig | [`zig/p/main_lorentz_tandem_repetitions.zig`](../../../zig/p/main_lorentz_tandem_repetitions.zig) |

The shared byte-output suite registers the package oracle, bounds, maximum
repetition profile, and malformed-input checks. The checker and suite have
not been run.
