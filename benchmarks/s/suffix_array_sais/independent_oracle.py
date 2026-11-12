"""Direct suffix-comparison verifier for SA-IS fixtures and bounds."""

from __future__ import annotations

import struct
from collections.abc import Sequence

try:
    from .primary_oracle import MAX_INPUT_LENGTH, MAX_TEXT_LENGTH
except ImportError:  # Direct invocation from this package directory.
    from primary_oracle import MAX_INPUT_LENGTH, MAX_TEXT_LENGTH


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or capacity is not None and (type(capacity) is not int or capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
        or input_is_null and values not in (None, [], ())
        or not input_is_null
        and values is not None
        and input_length is not None
        and input_length != len(values)
    ):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    count = values[0]
    if not 0 <= count <= MAX_TEXT_LENGTH or len(values) != count + 1:
        return -1, b""
    text = values[1:]
    if any(not 0 <= value <= 255 for value in text):
        return -1, b""
    order = sorted(range(count), key=lambda start: tuple(text[start:]))
    payload = struct.pack("<" + "q" * count, *order)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
