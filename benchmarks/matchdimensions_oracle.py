"""Independent scalar oracle for matching matrix dimensions."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 5
MAX_DIMENSION = 65535


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
) -> int:
    if values is None:
        return -1
    if (not isinstance(values, (list, tuple)) or len(values) != 4
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if any(value < 0 or value > MAX_DIMENSION for value in values):
        return -1
    return int(values[0] == values[2] and values[1] == values[3])
