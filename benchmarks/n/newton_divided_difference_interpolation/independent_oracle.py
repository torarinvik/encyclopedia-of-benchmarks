"""Independent Lagrange-form reference for finite-field interpolation queries."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import INVALID_RESULT, MAX_PARSEABLE_INPUT_LENGTH, MAX_NODES, MODULUS


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[tuple[int, ...], tuple[int, ...], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    count = values[0]
    if not 1 <= count <= MAX_NODES or input_length != 2 + 2 * count:
        return None
    nodes = tuple(values[1:1 + count])
    ordinates = tuple(values[1 + count:1 + 2 * count])
    query = values[-1]
    if (any(not 0 <= value < MODULUS for value in nodes + ordinates + (query,))
            or len(set(nodes)) != count):
        return None
    return nodes, ordinates, query


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    nodes, ordinates, query = parsed
    answer = 0
    for index, (node, ordinate) in enumerate(zip(nodes, ordinates)):
        numerator = 1
        denominator = 1
        for other_index, other_node in enumerate(nodes):
            if other_index == index:
                continue
            numerator = numerator * (query - other_node) % MODULUS
            denominator = denominator * (node - other_node) % MODULUS
        answer = (answer + ordinate * numerator * pow(denominator, MODULUS - 2, MODULUS)) % MODULUS
    return answer


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
