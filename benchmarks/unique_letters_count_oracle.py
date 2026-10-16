"""Independent oracle for the R unique-letter frequency example."""

from __future__ import annotations

import struct

MAX_INPUT_LENGTH = 256
MAX_PACKED_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
LETTER_COUNT = 26
BYTES_PER_RECORD = 8
MAX_OUTPUT_BYTES = LETTER_COUNT * BYTES_PER_RECORD
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= MAX_PACKED_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    text_length = values[0]
    if not 0 <= text_length <= MAX_INPUT_LENGTH or len(values) != text_length + 1:
        return -1, b""
    text = values[1:]
    if any(not 0 <= value < 128 for value in text):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""

    frequencies = [0] * LETTER_COUNT
    first_seen: list[int] = []
    for byte in text:
        if 65 <= byte <= 90:
            letter = byte + 32
        elif 97 <= byte <= 122:
            letter = byte
        else:
            continue
        index = letter - 97
        if frequencies[index] == 0:
            first_seen.append(letter)
        frequencies[index] += 1

    required_capacity = min(text_length, LETTER_COUNT) * BYTES_PER_RECORD
    if output_capacity is not None and output_capacity < required_capacity:
        return -2, b""
    output = b"".join(
        struct.pack("<ii", letter, frequencies[letter - 97])
        for letter in first_seen
    )
    return len(first_seen), output
