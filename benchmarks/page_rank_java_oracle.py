"""Oracle for the pinned Java PageRank recurrence and teleport term."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_NODES = 1
MAX_NODES = 4
MIN_ITERATIONS = 1
MAX_ITERATIONS = 8
DAMPING = 0.5
MAX_INPUT_LENGTH = 2 + MAX_NODES * MAX_NODES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _finite(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def expected_result(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> list[float] | int:
    """Return Java's ordered PageRank values or an ABI error status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if not 2 + MIN_NODES * MIN_NODES <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if not all(_finite(value) for value in values):
        return INVALID_RESULT
    if values[0] != int(values[0]) or values[1] != int(values[1]):
        return INVALID_RESULT
    nodes, iterations = int(values[0]), int(values[1])
    if not MIN_NODES <= nodes <= MAX_NODES:
        return INVALID_RESULT
    if not MIN_ITERATIONS <= iterations <= MAX_ITERATIONS:
        return INVALID_RESULT
    if len(values) != 2 + nodes * nodes:
        return INVALID_RESULT
    matrix_values = values[2:]
    if any(value not in (0, 1) for value in matrix_values):
        return INVALID_RESULT
    matrix = [int(value) for value in matrix_values]
    for node in range(nodes):
        if matrix[node * nodes + node] != 0:
            return INVALID_RESULT

    outdegrees = [sum(matrix[row * nodes : (row + 1) * nodes]) for row in range(nodes)]
    ranks = [1.0 / nodes] * nodes
    for _ in range(iterations):
        new_ranks = [0.0] * nodes
        for target in range(nodes):
            incoming = 0.0
            for source in range(nodes):
                if matrix[source * nodes + target] == 1 and outdegrees[source] > 0:
                    incoming += ranks[source] / outdegrees[source]
            new_ranks[target] = (1.0 - DAMPING) + DAMPING * incoming
        ranks = new_ranks
    if output_is_null or (output_capacity is not None and output_capacity < nodes):
        return OUTPUT_ERROR
    return ranks
