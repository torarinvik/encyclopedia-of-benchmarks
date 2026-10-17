"""Independent bounded oracle for the pushdown-automaton language."""

from __future__ import annotations

MAX_BYTE_LENGTH = 256
MAX_INPUT_LENGTH = MAX_BYTE_LENGTH + 1
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int]) -> int:
    if not values or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        return INVALID_RESULT

    byte_length = values[0]
    if byte_length < 0 or byte_length > MAX_BYTE_LENGTH:
        return INVALID_RESULT
    if len(values) != byte_length + 1:
        return INVALID_RESULT

    payload = values[1:]
    if any(byte not in (48, 49, 50) for byte in payload):
        return INVALID_RESULT

    if byte_length == 0 or byte_length % 2 != 0:
        return 0

    half = byte_length // 2
    if any(byte not in (49, 50) for byte in payload[:half]):
        return 0
    if any(byte != 48 for byte in payload[half:]):
        return 0
    return 1
