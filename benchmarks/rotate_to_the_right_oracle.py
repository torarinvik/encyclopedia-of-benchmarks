"""Independent oracle for bounded right rotation of linked-list values."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_PLACES = 1_000_000
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 4
MAX_OUTPUT_BYTES = 8 * MAX_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the ABI result and bytes for [n, places, values...]."""
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
            or (input_is_null and (values or declared_length == 0))
            or (not input_is_null and declared_length != len(values))
            or declared_length > MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    if input_is_null or len(values) < 3:
        return -1, b""

    n, places = values[0], values[1]
    if not 1 <= n <= MAX_N or places < -MAX_PLACES or places > MAX_PLACES:
        return -1, b""
    if len(values) != n + 2:
        return -1, b""
    list_values = values[2:]
    if any(not I32_MIN <= value <= I32_MAX for value in list_values):
        return -1, b""

    shift = places % n
    rotated = list_values[n - shift:] + list_values[:n - shift] if shift else list_values
    encoded = b"".join(struct.pack("<q", value) for value in rotated)
    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
