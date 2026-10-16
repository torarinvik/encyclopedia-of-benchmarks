"""Bounded reference oracle for the pinned Python Trifid cipher."""

from __future__ import annotations

MAX_TEXT_LENGTH = 256
DEFAULT_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ."
COORDINATES = "111 112 113 121 122 123 131 132 133 211 212 213 221 222 223 231 232 233 311 312 313 321 322 323 331 332 333".split()


def expected_output(values: list[int] | tuple[int, ...], capacity: int | None = None) -> tuple[int, bytes]:
    """Return `(output length, bytes)` for `[mode, period, n, 27, text..., alphabet...]`."""
    if (not isinstance(values, (list, tuple)) or len(values) < 4
            or any(type(v) is not int or not -(2**63) <= v < 2**63 for v in values)):
        return -1, b""
    mode, period, n, alphabet_n = values[:4]
    if (mode not in (0, 1) or not 1 <= period <= MAX_TEXT_LENGTH
            or not 0 <= n <= MAX_TEXT_LENGTH or alphabet_n != 27
            or len(values) != 4 + n + alphabet_n):
        return -1, b""
    raw_text, raw_alphabet = values[4:4+n], values[4+n:]
    if any(not 0 <= x <= 127 for x in raw_text + raw_alphabet):
        return -1, b""
    # Match Python's ASCII uppercasing and space stripping used by __prepare.
    alphabet = bytes(raw_alphabet).decode("ascii").replace(" ", "").upper()
    message = bytes(raw_text).decode("ascii").replace(" ", "").upper()
    if len(alphabet) != 27 or len(set(alphabet)) != 27:
        return -1, b""
    if any(char not in alphabet for char in message):
        return -1, b""
    if mode == 1 and len(message) == 0:
        result = ""
    else:
        enc = dict(zip(alphabet, COORDINATES))
        dec = {v: k for k, v in enc.items()}
        output: list[str] = []
        for start in range(0, len(message), period):
            block = message[start:start + period]
            if mode == 0:
                digits = "".join(enc[ch][axis] for axis in range(3) for ch in block)
                output.extend(dec[digits[i:i+3]] for i in range(0, len(digits), 3))
            else:
                digits = "".join(enc[ch] for ch in block)
                k = len(block)
                output.extend(dec[digits[i] + digits[k+i] + digits[2*k+i]] for i in range(k))
        result = "".join(output)
    encoded = result.encode("ascii")
    if capacity is not None and capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
