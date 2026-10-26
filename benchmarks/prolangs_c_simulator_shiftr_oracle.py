"""Independent 24-bit arithmetic-right-shift model for SHIFTR_P."""
from collections.abc import Sequence

MAX_INPUT_LENGTH = 2
WORD_MASK = (1 << 24) - 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) != 2:
        return INVALID_RESULT
    if any(type(value) is not int for value in values):
        return INVALID_RESULT
    operand, value = values
    if not (0 <= operand <= 255 and 0 <= value <= WORD_MASK):
        return INVALID_RESULT
    register = operand >> 4
    shift_count = (operand & 15) + 1
    if register >= 10:
        return INVALID_RESULT
    # Reconstruct the 24-bit source's bit-array operation directly.
    sign = (value >> 23) & 1
    result = 0
    for output_bit in range(24):
        source_bit = sign if output_bit < shift_count else (value >> (23 - (output_bit - shift_count))) & 1
        result = (result << 1) | source_bit
    return result
