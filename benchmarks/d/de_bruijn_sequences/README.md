# De Bruijn sequence generation

Generate the lexicographically smallest k-ary de Bruijn cycle with the
Fredricksen–Kessler–Maiorana (FKM) necklace-concatenation construction, then
append its first `order - 1` symbols to make cyclic windows explicit in a
linear byte string. The cycle contains every length-`order` word over the
alphabet exactly once.

## Contract

The exported C ABI symbol is
`de_bruijn_sequences(const int64_t *input, size_t length, uint8_t *output,
size_t capacity)` in the `i64_array_bytes_output` family.

Input is exactly `[alphabet_size, order]`. `alphabet_size` is 2 through 10,
`order` is 1 through 16, and `alphabet_size ** order` must not exceed 10,000.
Symbols are the ASCII bytes `0` through `alphabet_size - 1`. The returned
sequence length is `alphabet_size ** order + order - 1`, at most 10,003 bytes.
The function returns the number of bytes written, `-1` for a malformed or
out-of-profile input, and `-2` for a null output pointer or insufficient
capacity. Errors leave output untouched.

The maximum profile `[10, 4]` corresponds to the decimal four-digit lock
construction. Smaller profiles are used for exact fixtures. The output is a
linearization of a cycle; its trailing `order - 1` symbols repeat its prefix.

## Algorithm and complexity

The recursion constructs the necklaces in lexicographic order. At each
position it first copies the symbol one current period earlier, then tries
larger symbols and extends the candidate period. Whenever a completed
candidate's period divides the requested order, its period-length prefix is
emitted. The concatenation yields a de Bruijn cycle. FKM generation takes
`O(k^n)` output time and `O(n)` auxiliary storage; recursion depth is at most
16. The caller supplies the output buffer.

The primary oracle uses the FKM recurrence. The independent verifier checks
alphabet membership, cyclic-prefix extension, and uniqueness of every
length-`order` window using a base-`k` word index.

## Workload and files

[`workload.json`](workload.json) includes binary and ternary exact fixtures,
the canonical `[10, 4]` measurement profile, malformed domains, and output
capacity failures. The oracles are [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py).
[`verify_workload.py`](verify_workload.py) is a static inventory and fixture
checker; it does not launch language ports.

## Implementations

| Language | Source |
|---|---|
| C | [`c/d/de_bruijn_sequences.c`](../../../c/d/de_bruijn_sequences.c) |
| C3 | [`c3/d/de_bruijn_sequences.c3`](../../../c3/d/de_bruijn_sequences.c3) |
| C++ | [`cpp/d/de_bruijn_sequences.cpp`](../../../cpp/d/de_bruijn_sequences.cpp) |
| Elisa | [`elisa/d/de_bruijn_sequences.elisa`](../../../elisa/d/de_bruijn_sequences.elisa) |
| Mojo | [`mojo/d/de_bruijn_sequences.mojo`](../../../mojo/d/de_bruijn_sequences.mojo) |
| Nim | [`nim/d/de_bruijn_sequences.nim`](../../../nim/d/de_bruijn_sequences.nim) |
| Odin | [`odin/d/de_bruijn_sequences.odin`](../../../odin/d/de_bruijn_sequences.odin) |
| Rust | [`rust/d/de_bruijn_sequences.rs`](../../../rust/d/de_bruijn_sequences.rs) |
| V | [`v/d/de_bruijn_sequences.v`](../../../v/d/de_bruijn_sequences.v) |
| Zig | [`zig/d/de_bruijn_sequences.zig`](../../../zig/d/de_bruijn_sequences.zig) |

See [RIGHTS.md](RIGHTS.md) for provenance and attribution.
