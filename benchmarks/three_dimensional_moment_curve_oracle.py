"""Primary arithmetic oracle for the source chapter's moment-curve drawing."""

from __future__ import annotations

from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or len(values) != 1
            or input_length is not None and (type(input_length) is not int or input_length != 1)
            or type(values[0]) is not int or not 0 <= values[0] <= 64):
        return -1, b""
    n = values[0]
    out = [n]
    for vertex in range(1, n + 1):
        out.extend((vertex, vertex * vertex, vertex * vertex * vertex))
    payload = b"".join(value.to_bytes(8, "little", signed=True) for value in out)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
