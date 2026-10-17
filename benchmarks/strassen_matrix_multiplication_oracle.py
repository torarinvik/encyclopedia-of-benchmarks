"""Independent naive oracle for the bounded Strassen matrix ABI."""
from __future__ import annotations

import struct

SUPPORTED_N = {1, 2, 4, 8}
MAX_OUTPUT_BYTES = 512
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if not isinstance(values, (list, tuple)) or not values:
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""
    n = values[0]
    if n not in SUPPORTED_N or len(values) != 1 + 2 * n * n:
        return -1, b""
    entries = values[1:]
    if any(value < -2 or value > 2 for value in entries):
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""

    split = n * n
    a = values[1:1 + split]
    b = values[1 + split:]
    product = [
        sum(a[row * n + k] * b[k * n + column] for k in range(n))
        for row in range(n)
        for column in range(n)
    ]
    encoded = b"".join(struct.pack("<q", value) for value in product)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
