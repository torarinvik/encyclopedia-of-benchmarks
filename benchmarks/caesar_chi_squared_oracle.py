"""Reference implementation of the pinned default chi-square Caesar decoder."""

from __future__ import annotations

from collections import Counter
import struct

FREQUENCIES = (
    0.08497, 0.01492, 0.02202, 0.04253, 0.11162, 0.02228, 0.02015,
    0.06094, 0.07546, 0.00153, 0.01292, 0.04025, 0.02406, 0.06749,
    0.07507, 0.01929, 0.00095, 0.07587, 0.06327, 0.09356, 0.02758,
    0.00978, 0.02560, 0.00150, 0.01994, 0.00077,
)
MAX_TEXT_LENGTH = 128


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not 1 <= len(values) <= MAX_TEXT_LENGTH + 1
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or not 0 <= values[0] <= MAX_TEXT_LENGTH
            or len(values) != values[0] + 1
            or any(not 0 <= value <= 127 for value in values[1:])):
        return -1, b""

    ciphertext = bytes(values[1:])
    candidates: list[tuple[float, bytes, int]] = []
    for shift in range(26):
        decoded = bytearray()
        for byte in ciphertext:
            if 65 <= byte <= 90:
                decoded.append(97 + (byte - 65 - shift) % 26)
            elif 97 <= byte <= 122:
                decoded.append(97 + (byte - 97 - shift) % 26)
            else:
                decoded.append(byte)
        counts = Counter(byte for byte in decoded if 97 <= byte <= 122)
        score = 0.0
        for index, letter in enumerate(range(97, 123)):
            occurrences = counts[letter]
            if occurrences:
                expected = FREQUENCIES[index] * occurrences
                score += ((occurrences - expected) ** 2) / expected
        candidates.append((score, bytes(decoded), shift))

    score, plaintext, shift = min(candidates)
    return shift, struct.pack("<d", score) + plaintext
