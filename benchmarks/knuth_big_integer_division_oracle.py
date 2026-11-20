"""Independent arbitrary-precision oracle for Knuth big-integer division."""

from __future__ import annotations

from collections.abc import Sequence

MAX_DIGITS = 64


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 4 or len(values) > 2 + 2 * MAX_DIGITS:
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    len_a, len_b = values[0], values[1]
    if not 1 <= len_a <= MAX_DIGITS or not 1 <= len_b <= MAX_DIGITS or len(values) != 2 + len_a + len_b:
        return -1, b""
    a, b = values[2:2 + len_a], values[2 + len_a:]
    for text in (a, b):
        if any(byte < 48 or byte > 57 for byte in text) or (len(text) > 1 and text[0] == 48):
            return -1, b""
    if b == [48]:
        return -1, b""
    dividend = int(bytes(a).decode("ascii"))
    divisor = int(bytes(b).decode("ascii"))
    quotient, remainder = divmod(dividend, divisor)
    payload = f"{quotient}:{remainder}".encode("ascii")
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < len(payload))):
        return -2, b""
    return len(payload), payload
