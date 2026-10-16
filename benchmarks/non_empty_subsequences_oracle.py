"""Independent oracle for Go's include-first nonempty rune subsequences."""

from __future__ import annotations

import struct

MAX_RUNES = 8
MAX_INPUT_LENGTH = MAX_RUNES + 2  # count plus one over-bound rune
MAX_OUTPUT_BYTES = 5116
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def is_unicode_scalar(value: int) -> bool:
    return (0 <= value <= 0x10FFFF
            and not 0xD800 <= value <= 0xDFFF)


def expected_output(input_values: list[int]) -> tuple[int, bytes]:
    """Return (row count, packed rows), or (-1, empty bytes) for invalid input."""
    if (not isinstance(input_values, list) or not 1 <= len(input_values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int for value in input_values)):
        return INVALID_RESULT, b""

    count, runes = input_values[0], input_values[1:]
    if (not 1 <= count <= MAX_RUNES or len(runes) != count
            or any(not is_unicode_scalar(rune) for rune in runes)):
        return INVALID_RESULT, b""

    output = bytearray()
    selected: list[int] = []
    rows = 0

    def enumerate_include_first(start: int) -> None:
        nonlocal rows
        for index in range(start, count):
            selected.append(runes[index])
            output.extend(struct.pack("<I", len(selected)))
            for rune in selected:
                output.extend(struct.pack("<i", rune))
            rows += 1
            enumerate_include_first(index + 1)
            selected.pop()

    enumerate_include_first(0)
    return rows, bytes(output)
