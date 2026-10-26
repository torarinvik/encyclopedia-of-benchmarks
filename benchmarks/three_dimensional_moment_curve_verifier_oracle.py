"""Independent recurrence-based verifier for moment-curve coordinates."""

from __future__ import annotations

from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or len(values) != 1
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or type(values[0]) is not int or values[0] < 0 or values[0] > 64):
        return -1, b""
    n = values[0]
    output = [n]
    x = y = z = 0
    for vertex in range(1, n + 1):
        x += 1
        y += 2 * vertex - 1
        z += 3 * vertex * vertex - 3 * vertex + 1
        output.extend((x, y, z))
    payload = b"".join(int(value).to_bytes(8, "little", signed=True) for value in output)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
