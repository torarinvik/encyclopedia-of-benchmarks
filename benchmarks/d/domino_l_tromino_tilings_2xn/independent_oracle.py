"""Scalar recurrence reference for the bounded 2-by-n tile count."""
from __future__ import annotations

MAX_WIDTH = 32


def recurrence_count(width: int) -> int | None:
    if type(width) is not int or not 0 <= width <= MAX_WIDTH:
        return None
    terms = [1, 1, 2]
    if width < len(terms):
        return terms[width]
    for n in range(3, width + 1):
        terms.append(2 * terms[n - 1] + terms[n - 3])
    return terms[width]


def expected_result(values, *, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    if (values is None or input_is_null or not isinstance(values, (list, tuple))
            or len(values) != 1 or type(values[0]) is not int
            or not -(1 << 63) <= values[0] < (1 << 63)):
        return -1
    if input_length is not None and (type(input_length) is not int or input_length != 1):
        return -1
    result = recurrence_count(values[0])
    return -1 if result is None else result
