"""Oracle for the Python/Rust PageRank variant with dangling-mass redistribution."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_NODES = 2
MAX_NODES = 4
MAX_ITERATIONS = 8
DAMPING = 0.5
TOLERANCE = 0.0
MAX_INPUT_LENGTH = 2 + MAX_NODES * MAX_NODES
MAX_OUTPUT_LENGTH = MAX_NODES
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
    """Return ordered ranks, or the benchmark ABI error status."""
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
    if not MIN_NODES <= nodes <= MAX_NODES or not 0 <= iterations <= MAX_ITERATIONS:
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
    base_random_jump = (1.0 - DAMPING) / nodes
    for _ in range(iterations):
        dangling_sum = sum(ranks[node] for node in range(nodes) if outdegrees[node] == 0)
        dangling_share = (dangling_sum * DAMPING) / nodes
        base_rank = base_random_jump + dangling_share
        new_ranks: list[float] = []
        for target in range(nodes):
            incoming = 0.0
            for source in range(nodes):
                if matrix[source * nodes + target] == 1:
                    incoming += ranks[source] / outdegrees[source]
            new_ranks.append(base_rank + incoming * DAMPING)
        total_diff = sum(abs(ranks[node] - new_ranks[node]) for node in range(nodes))
        ranks = new_ranks
        if total_diff < TOLERANCE:
            break
    if output_is_null or (output_capacity is not None and output_capacity < nodes):
        return OUTPUT_ERROR
    return ranks
