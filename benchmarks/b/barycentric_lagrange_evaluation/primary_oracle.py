"""Barycentric evaluation of a bounded finite-field interpolant."""

from __future__ import annotations

from collections.abc import Sequence

ALGORITHM = "barycentric_lagrange_evaluation"
MODULUS = 998244353
MAX_NODES = 8
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_NODES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 128
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> tuple[list[int], list[int], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
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
    nodes = list(values[1:1 + count])
    ordinates = list(values[1 + count:1 + 2 * count])
    query = values[-1]
    if (any(not 0 <= value < MODULUS for value in nodes + ordinates + [query])
            or len(set(nodes)) != count):
        return None
    return nodes, ordinates, query


def _inverse(value: int) -> int:
    return pow(value % MODULUS, MODULUS - 2, MODULUS)


def barycentric_value(nodes: Sequence[int], ordinates: Sequence[int], query: int) -> int:
    """Evaluate the second barycentric form using reciprocal nodal weights."""
    count = len(nodes)
    weights = [1] * count
    for index, node in enumerate(nodes):
        product = 1
        for other_index, other_node in enumerate(nodes):
            if other_index != index:
                product = product * (node - other_node) % MODULUS
        weights[index] = _inverse(product)

    for index, node in enumerate(nodes):
        if query == node:
            return ordinates[index]

    numerator = 0
    denominator = 0
    for weight, ordinate, node in zip(weights, ordinates, nodes):
        term = weight * _inverse(query - node) % MODULUS
        numerator = (numerator + term * ordinate) % MODULUS
        denominator = (denominator + term) % MODULUS
    if denominator == 0:
        raise ArithmeticError("barycentric denominator vanished outside the node set")
    return numerator * _inverse(denominator) % MODULUS


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    nodes, ordinates, query = parsed
    return barycentric_value(nodes, ordinates, query)
