"""Oracle for the bounded linked-list reverse formatter."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VALUES = 256
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALUES + 2
MAX_OUTPUT_BYTES = 3836
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the ABI result and bytes for a direct array of list values."""
    if input_length is None:
        declared_length = len(values) if isinstance(values, (list, tuple)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared_length = input_length
    else:
        return -1, b""
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)
            or type(input_is_null) is not bool
            or (input_is_null and (len(values) != 0 or declared_length != 0))
            or (not input_is_null and declared_length != len(values))
            or declared_length > MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    if len(values) > MAX_VALUES or any(not I32_MIN <= value <= I32_MAX for value in values):
        return -1, b""

    encoded = " <- ".join(str(value) for value in reversed(values)).encode("ascii")
    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
