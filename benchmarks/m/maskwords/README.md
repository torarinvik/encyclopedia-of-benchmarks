# Mask words

This package ports the pinned R maskWords routine to nine languages. It splits the text on literal spaces, lowercases only the exact standalone spellings birds/Birds/BIRDS, market/Market/MARKET, and street/Street/STREET, replaces lowercase whole-word matches, removes line feeds after replacement, and joins the split tokens with one space.

The packed input is [text_byte_length, text_ascii_bytes..., mask_byte_length, mask_printable_ascii_bytes...]. Text may contain byte values 1 through 127 except NUL, up to 512 bytes; line feeds are accepted and removed, while carriage returns and other ASCII control bytes are preserved. The mask is 0 through 16 printable ASCII bytes, excluding backslash. Literal-space splitting preserves leading and repeated spaces and follows R's omission of a final empty field.

The output contains the result bytes without a trailing NUL. The function returns the output byte count, -1 for invalid packed input, and -2 when the output capacity is too small. Empty text returns an empty byte string. The maximum output workspace is 1,447 bytes.

See [workload.json](workload.json), the [independent oracle](../../maskwords_oracle.py), and the [pinned R source](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/maskwords.r). The R manual documents the final-empty-field behavior of [strsplit](https://stat.ethz.ch/R-manual/R-devel/library/base/html/strsplit.html).

| Language | Port |
|---|---|
| C | [c/w/maskwords.c](../../../c/w/maskwords.c) |
| C3 | [c3/w/maskwords.c3](../../../c3/w/maskwords.c3) |
| C++ | [cpp/w/maskwords.cpp](../../../cpp/w/maskwords.cpp) |
| Elisa | [elisa/w/maskwords.elisa](../../../elisa/w/maskwords.elisa) |
| Nim | [nim/w/maskwords.nim](../../../nim/w/maskwords.nim) |
| Odin | [odin/w/maskwords.odin](../../../odin/w/maskwords.odin) |
| Rust | [rust/w/maskwords.rs](../../../rust/w/maskwords.rs) |
| V | [v/w/maskwords.v](../../../v/w/maskwords.v) |
| Zig | [zig/w/maskwords.zig](../../../zig/w/maskwords.zig) |

Focused byte-output verification is available with python3 benchmarks/verify_i64_array_bytes_output.py --algorithm maskwords.
