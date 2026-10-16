"""Oracle for the bounded pinned JavaScript railway-time conversion."""

from __future__ import annotations

MAX_INPUT_LENGTH = 10
MAX_PARSEABLE_INPUT_LENGTH = 12
MAX_OUTPUT_BYTES = 8
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def expected_output(values: list[int] | tuple[int, ...],
                   output_capacity: int = MAX_OUTPUT_BYTES) -> tuple[int, bytes]:
    """Convert one normalized 12-hour ASCII time or return an ABI error."""
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT, b""
    if values[0] != MAX_INPUT_LENGTH or len(values) != MAX_INPUT_LENGTH + 1:
        return INVALID_RESULT, b""

    text = values[1:]
    if any(not 0 <= value <= 127 for value in text):
        return INVALID_RESULT, b""
    if (text[2] != 58 or text[5] != 58 or tuple(text[8:10]) not in
            ((65, 77), (80, 77))):
        return INVALID_RESULT, b""
    digit_positions = (0, 1, 3, 4, 6, 7)
    if any(not 48 <= text[index] <= 57 for index in digit_positions):
        return INVALID_RESULT, b""

    hour = (text[0] - 48) * 10 + text[1] - 48
    minute = (text[3] - 48) * 10 + text[4] - 48
    second = (text[6] - 48) * 10 + text[7] - 48
    if not 1 <= hour <= 12 or not 0 <= minute <= 59 or not 0 <= second <= 59:
        return INVALID_RESULT, b""

    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if output_capacity < MAX_OUTPUT_BYTES:
        return INSUFFICIENT_CAPACITY_RESULT, b""

    is_pm = text[8] == 80
    hour24 = hour % 12 + (12 if is_pm else 0)
    result = bytes((
        48 + hour24 // 10, 48 + hour24 % 10, 58,
        text[3], text[4], 58, text[6], text[7],
    ))
    return len(result), result
