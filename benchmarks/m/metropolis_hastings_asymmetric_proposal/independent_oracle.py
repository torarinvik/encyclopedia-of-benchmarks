"""Independent rational-kernel reference for the bounded MH trace."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction

MAX_STATES = 8
MAX_STEPS = 64
MAX_INPUT_LENGTH = 267


def _parse(values: Sequence[int] | None) -> tuple[int, int, int, list[int], list[int], int, int] | None:
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 3
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return None
    n, steps, initial = values[:3]
    if not (2 <= n <= MAX_STATES and 0 <= steps <= MAX_STEPS and 0 <= initial < n):
        return None
    if len(values) != 3 + n + n * n + 3 * steps:
        return None
    weights_start = 3
    matrix_start = weights_start + n
    proposals_start = matrix_start + n * n
    draws_start = proposals_start + steps
    weights = list(values[weights_start:matrix_start])
    matrix = list(values[matrix_start:proposals_start])
    if any(not 1 <= weight <= 1024 for weight in weights):
        return None
    for state in range(n):
        row = matrix[state * n : (state + 1) * n]
        if any(not 0 <= item <= 1024 for item in row) or sum(row) != 1024:
            return None
    for step in range(steps):
        proposal = values[proposals_start + step]
        draw_num = values[draws_start + 2 * step]
        draw_den = values[draws_start + 2 * step + 1]
        if not 0 <= proposal < n or not 1 <= draw_den <= 1024 or not 0 <= draw_num < draw_den:
            return None
    return n, steps, initial, weights, matrix, proposals_start, draws_start


def _exact_transition_data(
    n: int, weights: list[int], matrix: list[int]
) -> list[list[Fraction]] | None:
    """Build the full proposal/acceptance kernel and check detailed balance."""
    acceptance = [[Fraction(0, 1) for _ in range(n)] for _ in range(n)]
    proposal_probability = [[Fraction(matrix[x * n + y], 1024) for y in range(n)] for x in range(n)]
    for x in range(n):
        for y in range(n):
            forward = matrix[x * n + y]
            if forward == 0:
                continue
            reverse = matrix[y * n + x]
            if x == y:
                acceptance[x][y] = Fraction(1, 1)
            elif reverse == 0:
                acceptance[x][y] = Fraction(0, 1)
            else:
                ratio = Fraction(weights[y] * reverse, weights[x] * forward)
                acceptance[x][y] = min(Fraction(1, 1), ratio)

    kernel = [[Fraction(0, 1) for _ in range(n)] for _ in range(n)]
    for x in range(n):
        for y in range(n):
            q = proposal_probability[x][y]
            if x == y:
                kernel[x][x] += q
            elif q:
                moved = q * acceptance[x][y]
                kernel[x][y] += moved
                kernel[x][x] += q - moved
        if sum(kernel[x], Fraction(0, 1)) != 1:
            return None
    for x in range(n):
        for y in range(x + 1, n):
            if weights[x] * kernel[x][y] != weights[y] * kernel[y][x]:
                return None
    return acceptance


def _trace(values: Sequence[int] | None) -> bytes | None:
    parsed = _parse(values)
    if parsed is None:
        return None
    n, steps, initial, weights, matrix, proposals_start, draws_start = parsed
    acceptance = _exact_transition_data(n, weights, matrix)
    if acceptance is None:
        return None
    current = initial
    trace = bytearray((current,))
    for step in range(steps):
        proposal = values[proposals_start + step]
        draw = Fraction(values[draws_start + 2 * step], values[draws_start + 2 * step + 1])
        if matrix[current * n + proposal] == 0:
            return None
        if draw < acceptance[current][proposal]:
            current = proposal
        trace.append(current)
    return bytes(trace)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool or input_is_null:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
        type(input_length) is not int
        or not isinstance(values, (tuple, list))
        or input_length != len(values)
    ):
        return -1, b""
    trace = _trace(values)
    if trace is None:
        return -1, b""
    if output_is_null or (capacity is not None and capacity < len(trace)):
        return -2, b""
    return len(trace), trace


def validate_result(values: Sequence[int] | None, output: bytes) -> bool:
    expected = _trace(values)
    return expected is not None and output == expected


oracle = expected_output
