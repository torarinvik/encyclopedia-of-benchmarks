# Shuffled shift cipher

This benchmark measures the deterministic `encrypt` path of the pinned
Python `ShuffledShiftCipher`. The optional random passcode default is excluded:
the workload always supplies a nonempty passcode.

## Input and output

The signed 64-bit input is
`[passcode_length, plaintext_length, passcode_ascii..., plaintext_ascii...]`.
Passcodes contain 1 through 20 ASCII letters or digits. The 20-character cap
matches the upper end of the source's generated passcode length. Plaintext
contains 0 through 256 characters from the source's 97-character alphabet:
`string.ascii_letters + string.digits + string.punctuation + " \t\n"`.
Because all accepted characters are ASCII, each input character is one byte.
The input has exactly `2 + passcode_length + plaintext_length` values.

To build the shuffled key, scan the 97-character alphabet in its declared
order. Add each character to the current segment; when it is in the passcode's
unique-character set, or when it is the final alphabet character, append the
segment in reverse and clear it. The source sorts the unique passcode
characters before membership checks; their order does not change this scan.

The shift is the alternating signed sum of the passcode codepoints, starting
with a positive term at index zero. If that sum is not positive, use the
passcode length. For each plaintext character, find its index in the shuffled
key and emit the key character at `(index + shift) % 97`. The output is the raw
ASCII ciphertext with no prefix or terminator, so its byte count equals the
plaintext length. Malformed or null input returns `-1` before output checks.
For a valid input, a null output pointer returns `-2` even when the
plaintext is empty; insufficient capacity also returns `-2` when it is below
the output byte length. Empty plaintext with a non-null output pointer and zero
capacity returns zero bytes.

## Pinned source

The source is TheAlgorithms/Python
[`shuffled_shift_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/shuffled_shift_cipher.py),
commit `e1a2a8b016001309a73d5fec4818c35cca139795`, class
`ShuffledShiftCipher`, method `encrypt` and its key/shift helpers.

The bounded byte-output contract and independent oracle are
[`workload.json`](workload.json) and
[`benchmarks/shuffled_shift_cipher_oracle.py`](../../shuffled_shift_cipher_oracle.py).
