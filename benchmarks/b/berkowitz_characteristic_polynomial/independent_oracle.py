"""Permutation expansion reference for det(xI-A), independent of Berkowitz."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import permutations

MAX_N = 7
MAX_MODULUS = 1_000_000_000
MAX_ENTRY = 1_000_000
MAX_VALID_INPUT_LENGTH = MAX_N * MAX_N + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = (MAX_N + 1) * 8
WORKSPACE_BYTES = 4096


def _decode(frame: Sequence[int] | None, length: int | None,
            input_is_null: bool) -> tuple[int, int, list[list[int]]] | None:
    if input_is_null or frame is None or not isinstance(frame, (list, tuple)):
        return None
    if length is not None and (
        type(length) is not int or length != len(frame)
        or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if not 3 <= len(frame) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in frame):
        return None
    n, modulus = frame[0], frame[1]
    if not 1 <= n <= MAX_N or not 2 <= modulus <= MAX_MODULUS:
        return None
    if len(frame) != 2 + n * n:
        return None
    entries = frame[2:]
    if any(value < -MAX_ENTRY or value > MAX_ENTRY for value in entries):
        return None
    matrix = [[entries[row * n + col] % modulus for col in range(n)]
              for row in range(n)]
    return n, modulus, matrix


def _permutation_polynomial(matrix: list[list[int]], modulus: int) -> list[int]:
    n = len(matrix)
    ascending = [0] * (n + 1)
    for permutation in permutations(range(n)):
        inversions = sum(
            permutation[i] > permutation[j]
            for i in range(n) for j in range(i + 1, n)
        )
        polynomial = [1 if inversions % 2 == 0 else modulus - 1]
        degree = 0
        for row, col in enumerate(permutation):
            if row == col:
                expanded = [0] * (degree + 2)
                negative_diagonal = (-matrix[row][row]) % modulus
                for power, coefficient in enumerate(polynomial):
                    expanded[power] = (expanded[power]
                                       + coefficient * negative_diagonal) % modulus
                    expanded[power + 1] = (expanded[power + 1] + coefficient) % modulus
                polynomial = expanded
                degree += 1
            else:
                factor = (-matrix[row][col]) % modulus
                polynomial = [coefficient * factor % modulus
                              for coefficient in polynomial]
        for power, coefficient in enumerate(polynomial):
            ascending[power] = (ascending[power] + coefficient) % modulus
    return list(reversed(ascending))


def _encode(coefficients: list[int]) -> bytes:
    return b"".join(value.to_bytes(8, "little", signed=True)
                    for value in coefficients)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    _, modulus, matrix = parsed
    output = _encode(_permutation_polynomial(matrix, modulus))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
