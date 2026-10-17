"""Independent oracle for bounded canonical-decimal big integer multiplication."""

from __future__ import annotations

MAX_DIGITS = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_DIGITS
MAX_OUTPUT_LENGTH = 2 * MAX_DIGITS
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _is_canonical_decimal(data: tuple[int, ...] | list[int]) -> bool:
    if not 1 <= len(data) <= MAX_DIGITS:
        return False
    if data == [48] or data == (48,):
        return True
    if not 49 <= data[0] <= 57:
        return False
    return all(48 <= byte <= 57 for byte in data[1:])


def expected_output(
    values: list[int] | tuple[int, ...],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Validate the packed operands and return `(status, product_bytes)`."""
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""

    len_a, len_b = values[:2]
    if not 1 <= len_a <= MAX_DIGITS or not 1 <= len_b <= MAX_DIGITS:
        return INVALID_RESULT, b""
    if len(values) != 2 + len_a + len_b:
        return INVALID_RESULT, b""

    operand_a = values[2:2 + len_a]
    operand_b = values[2 + len_a:]
    if (any(not 0 <= byte <= 127 for byte in operand_a + operand_b)
            or not _is_canonical_decimal(operand_a)
            or not _is_canonical_decimal(operand_b)):
        return INVALID_RESULT, b""

    digits_a = bytes(operand_a).decode("ascii")
    digits_b = bytes(operand_b).decode("ascii")
    product = str(int(digits_a) * int(digits_b)).encode("ascii")
    if len(product) > MAX_OUTPUT_LENGTH:
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and len(product) > capacity):
        return INSUFFICIENT_CAPACITY, b""
    return len(product), product
