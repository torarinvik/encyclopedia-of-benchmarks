# Gronsfeld cipher

This benchmark encrypts 7-bit ASCII text with a repeating decimal-digit key.

## Contract

- Input is [text bytes..., 0, key bytes...], where zero separates the text and key.
- Text length is 0 through 256 bytes; each byte is in 1 through 127. Key length is 0 through 64 bytes; each key byte must be an ASCII digit.
- ASCII letters are converted to uppercase and shifted by the repeating key digit. The key position is the original text byte index, so punctuation, spaces, and digits advance the key position even though those bytes pass through unchanged.
- An empty key is valid when the text contains no ASCII letters. It is invalid when the text contains a letter, matching the source division-by-zero behavior.
- The output has the same byte length as the text. Invalid input returns -1; insufficient output capacity returns -2. Errors leave the output buffer unchanged.

## Source semantics

The benchmark follows pinned [TheAlgorithms Python gronsfeld_cipher.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/gronsfeld_cipher.py). The source converts the text to uppercase, parses every key character as a decimal digit, and uses the absolute text index modulo the key length for each ASCII letter. Nonletters are copied at their original positions. The ABI narrows text to ASCII so uppercase mapping and byte offsets remain the same in every target language.

The indexed key rule distinguishes Gronsfeld from the existing Vigenere benchmark, which advances its key only when it processes a letter. The key alphabet also consists of decimal digits rather than letters.

## Workload and recording

The workload covers the source example, key cycling, key indexing across punctuation and spaces, lowercase normalization, empty text, empty-key edge cases, and malformed inputs. Build and record with the i64_array_bytes_output ABI:

- Build: python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm gronsfeld_cipher --language c
- Record: python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/g/gronsfeld_cipher/c/build.json

The nine implementations are in c/g/gronsfeld_cipher.c, c3/g/gronsfeld_cipher.c3, cpp/g/gronsfeld_cipher.cpp, elisa/g/gronsfeld_cipher.elisa, nim/g/gronsfeld_cipher.nim, odin/g/gronsfeld_cipher.odin, rust/g/gronsfeld_cipher.rs, v/g/gronsfeld_cipher.v, and zig/g/gronsfeld_cipher.zig.
