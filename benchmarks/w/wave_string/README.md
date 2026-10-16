# Wave String

For each ASCII letter in the input, this routine emits a copy of the full text with that one position uppercased. Variants follow input order; punctuation, digits, spaces, and other letters retain their original bytes. This matches the pinned Python implementation on the documented ASCII domain.

## Contract

- Input is a signed 64-bit array `[text_length, byte...]`, with text length from 0 through 512 and exactly `1 + text_length` values.
- Text bytes must be printable ASCII (`0x20` through `0x7e`); malformed input returns `-1`.
- The output repeats a little-endian u16 byte length followed by each modified string. The return value is the number of variants. Text with no letters returns zero and no output.
- Insufficient output capacity returns `-2` without writing. The 512-byte maximum bounds the encoded output to 263,168 bytes.
- The algorithm takes O(n²) time to produce up to n strings and O(1) auxiliary space beyond the output buffer.

The ASCII restriction keeps letter classification and uppercasing identical across runtimes. The upstream Python routine supports Unicode `str.isalpha()` and Unicode uppercasing; those cases are outside this portable contract.

## Source and verification

The source is [TheAlgorithms/Python `strings/wave_string.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/wave_string.py). `workload.json` covers empty and non-letter text, repeated letters, mixed case, punctuation, maximum output size, and malformed inputs. The verifier compares all nine ports with an independent per-letter transformation oracle.
