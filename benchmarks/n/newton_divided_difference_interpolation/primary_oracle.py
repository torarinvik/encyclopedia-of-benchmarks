"""Primary divided-difference evaluator for a bounded finite-field interpolant."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998_244_353
MAX_NODES = 12
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_NODES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> tuple[tuple[int, ...], tuple[int, ...], int] | None:
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


def _inverse(value: int) -> int:
    return pow(value, MODULUS - 2, MODULUS)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Use in-place Newton divided differences and nested Newton evaluation."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    nodes, ordinates, query = parsed
    differences = list(ordinates)
    for order in range(1, len(nodes)):
        for index in range(len(nodes) - 1, order - 1, -1):
            numerator = (differences[index] - differences[index - 1]) % MODULUS
            denominator = (nodes[index] - nodes[index - order]) % MODULUS
            differences[index] = numerator * _inverse(denominator) % MODULUS
    result = differences[-1]
    for index in range(len(nodes) - 2, -1, -1):
        result = (result * (query - nodes[index]) + differences[index]) % MODULUS
    return result
