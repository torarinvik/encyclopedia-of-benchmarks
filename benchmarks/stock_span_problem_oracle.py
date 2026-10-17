"""Oracle for the bounded Java/Python stock-span sequence benchmark."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_COUNT = 1
MAX_COUNT = 64
MIN_PRICE = -(1 << 31)
MAX_PRICE = (1 << 31) - 1
MAX_VALID_INPUT_LENGTH = MAX_COUNT + 1
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the result count and little-endian span bytes, or an ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if (len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    count = values[0]
    if not MIN_COUNT <= count <= MAX_COUNT or len(values) != count + 1:
        return INVALID_RESULT, b""
    prices = values[1:]
    if any(not MIN_PRICE <= price <= MAX_PRICE for price in prices):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""

    stack: list[int] = []
    spans: list[int] = []
    for day, price in enumerate(prices):
        while stack and prices[stack[-1]] <= price:
            stack.pop()
        spans.append(day + 1 if not stack else day - stack[-1])
        stack.append(day)
    output = b"".join(struct.pack("<q", span) for span in spans)
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return count, output
