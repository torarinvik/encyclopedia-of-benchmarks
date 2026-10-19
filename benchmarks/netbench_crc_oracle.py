"""Independent LP64 profile oracle for the bounded NetBench CRC kernel."""

from __future__ import annotations

MAX_LENGTH = 256
INVALID_RESULT = -1
MASK64 = (1 << 64) - 1
MASK32 = (1 << 32) - 1
POLYNOMIAL = 0x04C11DB7


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or value < 0 or value > 255 for value in values):
        return INVALID_RESULT

    table = [0] * 256
    for byte in range(256):
        remainder = byte << 24
        for _ in range(8):
            if remainder & 0x80000000:
                remainder = ((remainder << 1) ^ POLYNOMIAL) & MASK64
            else:
                remainder = (remainder << 1) & MASK64
        table[byte] = remainder

    crc = 0
    for byte in values:
        index = ((crc >> 24) ^ byte) & 0xFF
        crc = (((crc << 8) & MASK64) ^ table[index]) & MASK64
    return crc & MASK32
