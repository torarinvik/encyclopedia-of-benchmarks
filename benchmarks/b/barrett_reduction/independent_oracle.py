"""Direct-division semantics for Barrett reduction workload checking."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PARSEABLE_INPUT_LENGTH = 15
INVALID_RESULT = -1


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    modulus, count = values[0], values[1]
    if modulus < 2 or modulus > 65535 or count < 0 or count > 12:
        return None
    if input_length != 2 + count:
        return None
    limit = modulus * modulus
    operands = tuple(values[2:])
    if any(value < 0 or value >= limit for value in operands):
        return None
    return modulus, operands


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    modulus, operands = parsed
    return sum((index + 1) * (value % modulus + 1)
               for index, value in enumerate(operands))


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
