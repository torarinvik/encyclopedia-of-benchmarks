"""Oracle for the bounded Java/TypeScript/Ruby shuffle-array variants."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_N = 32
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_WORDS = 1 + 2 * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_WORDS
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode_input(values: Sequence[int] | None):
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None

    variant, n = values[0], values[1]
    if variant not in (0, 1) or not 0 <= n <= MAX_N:
        return None

    if variant == 0:
        draw_count = max(n - 1, 0)
        if len(values) != 2 + n + draw_count:
            return None
        items = list(values[2:2 + n])
        draws = list(values[2 + n:])
        if any(not I32_MIN <= item <= I32_MAX for item in items):
            return None
        for draw_index, chosen_index in enumerate(draws):
            current_index = n - 1 - draw_index
            if not 0 <= chosen_index <= current_index:
                return None
        return variant, n, items, draws

    if len(values) != 2 + 2 * n:
        return None
    items = list(values[2:])
    if any(not I32_MIN <= item <= I32_MAX for item in items):
        return None
    return variant, n, items, []


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return count-prefixed little-endian output or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, b""
    variant, n, items, draws = decoded
    if variant == 0:
        for draw_index, chosen_index in enumerate(draws):
            current_index = n - 1 - draw_index
            items[current_index], items[chosen_index] = items[chosen_index], items[current_index]
        result_values = items
    else:
        result_values = [value for pair in zip(items[:n], items[n:]) for value in pair]

    words = [len(result_values), *result_values]
    output = b"".join(struct.pack("<q", value) for value in words)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
