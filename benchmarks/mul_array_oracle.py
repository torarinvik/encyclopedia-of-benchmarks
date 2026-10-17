"""Independent oracle for the bounded signed-64-bit mul_array contract."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_INPUT_LENGTH = 9
MIN_FACTOR = 0
MAX_FACTOR = 99
MAX_PRODUCT = 913_517_247_483_640_899
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
) -> int:
    """Return the contract result; ``None`` models a null input pointer.

    A null pointer is valid only at length zero. For ordinary input, the
    optional length lets callers independently check a reported ABI length.
    """
    if values is None:
        return 1 if type(input_length) is int and input_length == 0 else INVALID_RESULT
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        return INVALID_RESULT
    if any(value < MIN_FACTOR or value > MAX_FACTOR for value in values):
        return INVALID_RESULT

    product = 1
    for value in values:
        product *= value
    return product
