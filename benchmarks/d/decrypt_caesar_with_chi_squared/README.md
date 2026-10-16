# Decrypt Caesar with chi-squared scoring

This benchmark tries all 26 Caesar decryption shifts and selects the candidate
with the smallest English-letter chi-squared score. It follows the default
mode of the pinned Python source: ASCII letters are folded to lowercase,
nonletters are preserved, and the source's per-letter expected count is
`frequency[letter] * observed_count_for_letter`. The selected candidate is
ordered by `(score, decoded plaintext bytes, shift)`, which makes ties
deterministic.

The ABI accepts a length followed by 0 to 128 ASCII bytes as signed 64-bit
input values. The return value is the selected backward shift in `0..25`. Output is an eight-byte
little-endian IEEE-754 binary64 score followed by the plaintext bytes. Invalid
input returns `-1`; insufficient output capacity returns `-2`. Custom
alphabets, custom frequency tables, and case-sensitive mode from the Python
helper are outside this shared contract.

The workload includes empty and punctuation-only inputs, short and longer
ciphertexts, and mixed-case input. See [`workload.json`](workload.json) and
[`benchmarks/verify_decrypt_caesar_with_chi_squared.py`](../../verify_decrypt_caesar_with_chi_squared.py).

| Language | Source |
| --- | --- |
| C | [`c/d/decrypt_caesar_with_chi_squared.c`](../../../c/d/decrypt_caesar_with_chi_squared.c) |
| C3 | [`c3/d/decrypt_caesar_with_chi_squared.c3`](../../../c3/d/decrypt_caesar_with_chi_squared.c3) |
| C++ | [`cpp/d/decrypt_caesar_with_chi_squared.cpp`](../../../cpp/d/decrypt_caesar_with_chi_squared.cpp) |
| Elisa | [`elisa/d/decrypt_caesar_with_chi_squared.elisa`](../../../elisa/d/decrypt_caesar_with_chi_squared.elisa) |
| Nim | [`nim/d/decrypt_caesar_with_chi_squared.nim`](../../../nim/d/decrypt_caesar_with_chi_squared.nim) |
| Odin | [`odin/d/decrypt_caesar_with_chi_squared.odin`](../../../odin/d/decrypt_caesar_with_chi_squared.odin) |
| Rust | [`rust/d/decrypt_caesar_with_chi_squared.rs`](../../../rust/d/decrypt_caesar_with_chi_squared.rs) |
| V | [`v/d/decrypt_caesar_with_chi_squared.v`](../../../v/d/decrypt_caesar_with_chi_squared.v) |
| Zig | [`zig/d/decrypt_caesar_with_chi_squared.zig`](../../../zig/d/decrypt_caesar_with_chi_squared.zig) |

