"""Fornberg's triangular finite-difference weight recurrence over F_p."""

from __future__ import annotations

import struct
from collections.abc import Sequence

ALGORITHM = "fornberg_finite_difference_weights"
MODULUS = 998244353
MAX_NODES = 8
MAX_DERIVATIVE = 3
MAX_VALID_INPUT_LENGTH = MAX_NODES + 3
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_NODES + 1)
WORKSPACE_BYTES = 512
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count, order, target = values[:3]
    if (not 1 <= count <= MAX_NODES or not 0 <= order <= MAX_DERIVATIVE
            or order >= count or len(values) != count + 3):
        return None
    nodes = list(values[3:])
    if not 0 <= target < MODULUS or any(not 0 <= node < MODULUS for node in nodes):
        return None
    if len(set(nodes)) != count:
        return None
    return count, order, target, nodes


def _inverse(value: int) -> int:
    return pow(value % MODULUS, MODULUS - 2, MODULUS)


def fornberg_weights(nodes: Sequence[int], target: int, order: int) -> list[int]:
    """Return one derivative column using the in-place triangular recurrence."""
    count = len(nodes)
    coefficients = [[0] * (MAX_DERIVATIVE + 1) for _ in range(MAX_NODES)]
    coefficients[0][0] = 1
    previous_product = 1
    for new_index in range(1, count):
        last_old = coefficients[new_index - 1].copy()
        product = 1
        for old_index in range(new_index):
            difference = (nodes[new_index] - nodes[old_index]) % MODULUS
            product = product * difference % MODULUS
            inverse_difference = _inverse(difference)
            factor = (nodes[new_index] - target) % MODULUS
            for derivative in range(min(new_index, order), -1, -1):
                current = coefficients[old_index][derivative]
                lower = coefficients[old_index][derivative - 1] if derivative else 0
                numerator = (factor * current - derivative * lower) % MODULUS
                coefficients[old_index][derivative] = numerator * inverse_difference % MODULUS
        product_inverse = _inverse(product)
        factor = (nodes[new_index - 1] - target) % MODULUS
        for derivative in range(min(new_index, order) + 1):
            lower = last_old[derivative - 1] if derivative else 0
            numerator = (derivative * lower - factor * last_old[derivative]) % MODULUS
            coefficients[new_index][derivative] = (
                previous_product * product_inverse % MODULUS * numerator % MODULUS
            )
        previous_product = product
    return [coefficients[index][order] for index in range(count)]


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    count, order, target, nodes = parsed
    weights = fornberg_weights(nodes, target, order)
    required = 8 * (count + 1)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or output_is_null
            or type(effective_capacity) is not int or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    return required, struct.pack("<" + "q" * (count + 1), count, *weights)
