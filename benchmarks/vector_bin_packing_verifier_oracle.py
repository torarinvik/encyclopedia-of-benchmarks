"""Independent first-fit verifier using per-bin residual capacity vectors."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 130


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 2 or len(values) > MAX_INPUT or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    count, width = values[0], values[1]
    if not 1 <= count <= 32 or not 1 <= width <= 4 or len(values) != 2 + count * width:
        return -1, b""
    items = [tuple(values[2 + i * width:2 + (i + 1) * width]) for i in range(count)]
    if any(component < 0 or component > 1000 for item in items for component in item):
        return -1, b""

    residual: list[list[int]] = []
    placed: list[int] = []
    for item in items:
        selected = -1
        for index, free in enumerate(residual):
            if all(component <= free[axis] for axis, component in enumerate(item)):
                selected = index
                break
        if selected < 0:
            selected = len(residual)
            residual.append([1000] * width)
        placed.append(selected)
        for axis, component in enumerate(item):
            residual[selected][axis] -= component
    bin_count = len(residual)
    loads = [[1000 - residual[b][axis] for axis in range(width)] for b in range(bin_count)]
    result = [bin_count]
    result.extend(placed)
    for row in loads:
        result.extend(row)
    payload = b"".join(struct.pack("<q", value) for value in result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
