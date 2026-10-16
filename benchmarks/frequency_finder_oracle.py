"""Independent oracle for the Python English frequency match score."""

from __future__ import annotations

MAX_TEXT_LENGTH = 1024
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1  # admit a one-byte over-bound input
INVALID_RESULT = -1
ETAOIN = "ETAOINSHRDLCUMWFGYPBVKJXQZ"


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    if len(values) > MAX_TEXT_LENGTH or any(not 0 <= byte <= 127 for byte in values):
        return INVALID_RESULT

    counts = [0] * 26
    for byte in values:
        if 97 <= byte <= 122:
            byte -= 32
        if 65 <= byte <= 90:
            counts[byte - 65] += 1

    order = sorted(range(26), key=lambda i: (counts[i], ETAOIN.index(chr(65 + i))), reverse=True)
    ordered_letters = [chr(65 + i) for i in order]
    return sum(letter in ordered_letters[:6] for letter in ETAOIN[:6]) + sum(
        letter in ordered_letters[-6:] for letter in ETAOIN[-6:]
    )
