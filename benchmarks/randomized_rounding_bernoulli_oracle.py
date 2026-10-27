"""Exact supplied-randomness oracle for basic independent randomized rounding."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 16
MAX_INPUT = 65
MAX_OUTPUT_BYTES = 16


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
    if len(values) < 5 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 4 * n:
        return -1, b""
    decisions: list[int] = []
    for index in range(n):
        x_num, x_den, u_num, u_den = values[1 + 4*index:5 + 4*index]
        if not 0 <= x_num <= x_den <= 32 or x_den < 1 or not 0 <= u_num < u_den <= 32 or u_den < 1:
            return -1, b""
        decisions.append(int(u_num * x_den < x_num * u_den))
    payload = bytes(decisions)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
