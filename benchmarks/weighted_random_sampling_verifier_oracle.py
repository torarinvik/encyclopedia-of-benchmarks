"""Independent repeated-multiplication verifier for weighted key selection."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_INPUT = 50


def _power(base: int, exponent: int) -> int:
    result = 1
    for _ in range(exponent):
        result *= base
    return result


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
    if len(values) < 5 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, count = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= count <= n or len(values) != 2 + 3*n:
        return -1, b""
    weights, numerators, denominators = [], [], []
    for i in range(n):
        weight, numerator, denominator = values[2 + 3*i:5 + 3*i]
        if not 1 <= weight <= 3 or not 1 <= numerator < denominator <= 100:
            return -1, b""
        weights.append(weight)
        numerators.append(numerator)
        denominators.append(denominator)

    # Repeatedly select the greatest remaining key instead of sorting.
    available = list(range(n))
    selected = []
    for _ in range(count):
        best_position = 0
        for position in range(1, len(available)):
            candidate = available[position]
            incumbent = available[best_position]
            lhs = _power(numerators[candidate], weights[incumbent]) * _power(denominators[incumbent], weights[candidate])
            rhs = _power(numerators[incumbent], weights[candidate]) * _power(denominators[candidate], weights[incumbent])
            if lhs > rhs or lhs == rhs and candidate < incumbent:
                best_position = position
        selected.append(available.pop(best_position))
    payload = b"".join(struct.pack("<q", item) for item in selected)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
