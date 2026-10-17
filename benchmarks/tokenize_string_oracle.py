"""Independent oracle for the bounded AArch64 string tokenizer contract."""

from __future__ import annotations

MAX_TEXT_LENGTH = 128
MAX_TOKEN_COUNT = 19
MAX_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + 1  # permits one over-bound text fixture
MAX_OUTPUT_LENGTH = MAX_TEXT_LENGTH + 2
SEPARATOR_BYTES = frozenset((44, 46, 58))
MIN_TEXT_BYTE = 32
MAX_TEXT_BYTE = 126
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: list[int] | tuple[int, ...],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Validate packed input and return `(status, count-prefixed token bytes)`."""
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""

    length, separator = values[:2]
    if not 0 <= length <= MAX_TEXT_LENGTH or len(values) != 2 + length:
        return INVALID_RESULT, b""
    if separator not in SEPARATOR_BYTES:
        return INVALID_RESULT, b""

    text = values[2:]
    if any(not MIN_TEXT_BYTE <= byte <= MAX_TEXT_BYTE for byte in text):
        return INVALID_RESULT, b""
    token_count = 1 + sum(byte == separator for byte in text)
    if token_count > MAX_TOKEN_COUNT:
        return INVALID_RESULT, b""

    token_buffer = bytes(0 if byte == separator else byte for byte in text) + b"\x00"
    output = bytes((token_count,)) + token_buffer
    if len(output) > MAX_OUTPUT_LENGTH:
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and len(output) > capacity):
        return INSUFFICIENT_CAPACITY, b""
    return len(output), output
