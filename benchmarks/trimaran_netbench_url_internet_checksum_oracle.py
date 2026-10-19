"""Oracle for the bounded Trimaran NetBench URL checksum helper profile."""

from __future__ import annotations

MAX_BYTES = 64
MAX_INPUT_LENGTH = MAX_BYTES + 2
INVALID_RESULT = -1
MASK64 = (1 << 64) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    mode, count = values[:2]
    if type(mode) is not int or mode not in (0, 1):
        return INVALID_RESULT
    if type(count) is not int or not 0 <= count <= MAX_BYTES or len(values) != count + 2:
        return INVALID_RESULT
    data = values[2:]
    if any(type(byte) is not int or not 0 <= byte <= 255 for byte in data):
        return INVALID_RESULT

    # Preserve the pinned C helper's 64-bit unsigned-long accumulation: it
    # adds the promoted bitwise complement of each native little-endian word,
    # then adds an odd trailing byte without complementing it.
    total = 0
    index = 0
    while index + 1 < count:
        word = data[index] | (data[index + 1] << 8)
        total = (total - word - 1) & MASK64
        index += 2
    if index < count:
        total = (total + data[index]) & MASK64
    while total >> 16:
        total = (total & 0xFFFF) + (total >> 16)
    if mode == 1:
        total = ((total >> 8) | ((total << 8) & 0xFF00)) & 0xFFFF
    return total
