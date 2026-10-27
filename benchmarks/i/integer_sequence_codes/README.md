# Integer sequence code modes

This bounded profile implements the elementary code families that DOI 84 specifies directly: unary, minimal binary, Elias Cγ, Elias Cδ, Golomb with an explicit parameter, Elias–Fano, binary interpolative coding, the basic byte-aligned code, Simple-9, and one explicit PForDelta exception-format refinement. It keeps them as modes of one package because they share the same bounded integer-sequence input.

## Contract

The `i64_array_bytes_output` input is `[mode,n,parameter,values...]`, with exactly `n` values and `1 <= n <= 32`. Bit-based modes concatenate code bits MSB-first, pack them into bytes, and zero-pad unused low bits of the last byte. Mode 7 emits the byte-aligned code bytes directly. Success returns the number of binary bytes written. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writing. Maximum input length is 35 words, maximum output is 512 bytes, and workspace is 8,704 bytes.

| Mode | Method | Parameter and domain |
|---:|---|---|
| 0 | Unary | `parameter=0`; values 0..31; each value emits that many `1` bits then `0`. |
| 1 | Minimal binary | `parameter=U`, 2..1,000,000; each value is in `[0,U)`. Short codewords are assigned to the first `2^k-U` values, where `k=ceil(log2 U)`. |
| 2 | Elias Cγ | `parameter=0`; values 0..1,000,000. For `q=floor(log2(x+1))`, emit unary `q`, then the `q`-bit offset `x+1-2^q`. |
| 3 | Elias Cδ | `parameter=0`; values 0..1,000,000. Encode `q=floor(log2(x+1))` with Cγ, then append the `q`-bit offset. |
| 4 | Golomb | `parameter=b`, 1..128; values 0..127 are coded directly as quotient `x div b` in unary plus remainder `x mod b` in minimal binary over `[0,b)`. |
| 5 | Elias–Fano | `parameter=U`, 2..4,096; values are strictly increasing in `[0,U)`. Use `k=floor(log2(U/n))`, emit unary bucket occupancies in bucket order, then each value's `k` low bits in sequence order. |
| 6 | Binary interpolative | `parameter=U`, 2..4,096; values are strictly increasing in `[0,U)`. Recursively encode the lower-middle value using its narrowed feasible range and minimal binary; process the left range, then the right range. |
| 7 | Basic byte-aligned code | `parameter=0`; values 0..1,000,000. Encode each value as big-endian 7-bit groups; set the top bit on every continuing byte and clear it on the final byte. Zero is one zero byte. |
| 8 | Simple-9 | `parameter=0`; values 0..2²⁸−1. Select the first fitting layout from the table below, put the selector in the high 4 bits and its values in the next 28 bits; zero-pad unused fields and any remaining low payload bits in a final word. |
| 9 | PForDelta bounded variant | `parameter=k`, 1..20; values 0..1,000,000. Emit each value's low `k` bits, a 6-bit exception count, then sorted `(zero-based position, full 20-bit value)` exception records. Position width is `ceil(log2(n))` (zero bits for a one-value block). |

Simple-9 selector layouts are `(selector, values per word, bits per value)`: `(0,28,1)`, `(1,14,2)`, `(2,9,3)`, `(3,7,4)`, `(4,5,5)`, `(5,4,7)`, `(6,3,9)`, `(7,2,14)`, `(8,1,28)`. The encoder greedily uses the first layout that fits the next values, padding the final word with zero values. Each 32-bit word contributes its bits most-significant-first to the packed output stream.

Mode 9 is a clean-room bounded PForDelta refinement: the chapter identifies block-width packing and exceptions but notes that exception formats vary. This profile fixes one explicit sorted-position/full-value record layout for a single block of at most 32 values; it is not presented as the chapter's unique canonical exception format.

Mode 4 profiles direct-value Golomb coding with caller-supplied `b`; the chapter's monotone-gap conversion and parameter-estimation step are not part of this call. Elias–Fano emits the unary bucket-count stream before the low-bit stream, making the chapter's two components deterministic in this benchmark. Binary interpolative coding chooses the lower middle item; the chapter permits any middle item. For modes 0–6, 8, and 9, the packed result is the bitstream itself with final low-bit zero padding; mode 7 is already byte-aligned.

The chapter also surveys `(S,C)`-byte-aligned variants, Simple-9 extensions, PForDelta variants, and other static codes. This package's byte-aligned, Simple-9, and PForDelta modes are bounded explicit profiles; the chapter does not prescribe a single `(S,C)` mapping or PForDelta exception format, so mode 9 selects and documents one format refinement. Cited packed-code variants are not expanded. The existing [`fibonacci_integer_code`](../fibonacci_integer_code/README.md) covers the separate Fibonacci family.

## Files

- [`workload.json`](workload.json)
- [Primary mode oracle](../../integer_sequence_codes_oracle.py)
- [Independent string-form verifier oracle](../../integer_sequence_codes_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/i/integer_sequence_codes.c`](../../../c/i/integer_sequence_codes.c) |
| C3 | [`c3/i/integer_sequence_codes.c3`](../../../c3/i/integer_sequence_codes.c3) |
| C++ | [`cpp/i/integer_sequence_codes.cpp`](../../../cpp/i/integer_sequence_codes.cpp) |
| Elisa | [`elisa/i/integer_sequence_codes.elisa`](../../../elisa/i/integer_sequence_codes.elisa) |
| Nim | [`nim/i/integer_sequence_codes.nim`](../../../nim/i/integer_sequence_codes.nim) |
| Odin | [`odin/i/integer_sequence_codes.odin`](../../../odin/i/integer_sequence_codes.odin) |
| Rust | [`rust/i/integer_sequence_codes.rs`](../../../rust/i/integer_sequence_codes.rs) |
| V | [`v/i/integer_sequence_codes.v`](../../../v/i/integer_sequence_codes.v) |
| Zig | [`zig/i/integer_sequence_codes.zig`](../../../zig/i/integer_sequence_codes.zig) |

## Provenance and rights

Source: “Compressing Integer Sequences,” *Encyclopedia of Algorithms*, DOI [`10.1007/978-1-4939-2864-4_84`](https://doi.org/10.1007/978-1-4939-2864-4_84). The chapter is copyrighted and grants no source-code license. All ports and oracles are clean-room implementations of the described coding behavior. No chapter prose, figures, or source code are reproduced. See [`RIGHTS.md`](RIGHTS.md).
