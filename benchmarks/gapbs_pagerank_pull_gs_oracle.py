"""Independent IEEE-binary32 oracle for the bounded GAPBS pull PageRank profile."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_NODES = 8
MAX_ITERATIONS = 20
MAX_INPUT_LENGTH = 2 + MAX_NODES * MAX_NODES
INVALID_RESULT = -1


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _calculate(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or not 6 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int for value in values):
        return INVALID_RESULT
    n, iterations = values[:2]
    if not 2 <= n <= MAX_NODES or not 0 <= iterations <= MAX_ITERATIONS:
        return INVALID_RESULT
    if len(values) != 2 + n * n:
        return INVALID_RESULT

    adjacency = [[0] * n for _ in range(n)]
    outdegree = [0] * n
    for row in range(n):
        for column in range(n):
            value = values[2 + row * n + column]
            if value not in (0, 1) or (row == column and value != 0):
                return INVALID_RESULT
            adjacency[row][column] = value
            outdegree[row] += value
        if outdegree[row] == 0:
            return INVALID_RESULT

    damping = _f32(0.85)
    init_score = _f32(_f32(1.0) / _f32(n))
    base_score = _f32(_f32(_f32(1.0) - damping) / _f32(n))
    scores = [init_score] * n
    outgoing = [_f32(scores[node] / _f32(outdegree[node])) for node in range(n)]

    # This oracle uses destination-column sums over the saved matrix. Each
    # score and contribution store is explicitly rounded to binary32.
    for _ in range(iterations):
        for target in range(n):
            incoming = _f32(0.0)
            for source in range(n):
                if adjacency[source][target]:
                    incoming = _f32(incoming + outgoing[source])
            product = _f32(damping * incoming)
            scores[target] = _f32(base_score + product)
            outgoing[target] = _f32(scores[target] / _f32(outdegree[target]))

    weighted = sum((node + 1) * float(scores[node]) for node in range(n))
    return math.floor(weighted * 100.0 + 0.5)


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the source-ordered PageRank checksum or the invalid-input code."""
    if type(input_is_null) is not bool or input_is_null or values is None:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT
    return _calculate(values)
