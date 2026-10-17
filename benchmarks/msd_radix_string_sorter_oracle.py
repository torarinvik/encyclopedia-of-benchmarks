"""Oracle for the bounded C# MSD radix string sorter."""

from __future__ import annotations

from collections.abc import Sequence

MAX_STRINGS = 256
MAX_STRING_LENGTH = 32
MAX_VALID_INPUT_LENGTH = 1 + MAX_STRINGS * (1 + MAX_STRING_LENGTH)
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MIN_CODE_UNIT = 0
MAX_CODE_UNIT = 255
INVALID_RESULT = -1
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def _fnv1a64(data: Sequence[int]) -> int:
    value = FNV_OFFSET_BASIS
    for byte in data:
        value ^= byte
        value = (value * FNV_PRIME) & MASK64
    return value


def expected_result(values: Sequence[int] | None) -> int | None:
    """Validate packed UTF-16 units, stable-sort strings, and hash the result."""
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None

    count = values[0]
    if not 0 <= count <= MAX_STRINGS:
        return None

    strings: list[tuple[int, ...]] = []
    position = 1
    for _ in range(count):
        if position >= len(values):
            return None
        string_length = values[position]
        position += 1
        if not 0 <= string_length <= MAX_STRING_LENGTH:
            return None
        end = position + string_length
        if end > len(values):
            return None
        code_units = tuple(values[position:end])
        if any(not MIN_CODE_UNIT <= code_unit <= MAX_CODE_UNIT
               for code_unit in code_units):
            return None
        strings.append(code_units)
        position = end

    if position != len(values):
        return None

    sorted_strings = sorted(strings)
    serialized = bytearray(count.to_bytes(2, byteorder="little", signed=False))
    for code_units in sorted_strings:
        serialized.append(len(code_units))
        serialized.extend(code_units)
    return _fnv1a64(serialized) & MASK63
