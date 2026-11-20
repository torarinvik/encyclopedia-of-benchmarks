"""Division-free Samuelson–Berkowitz characteristic-polynomial reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 7
MAX_MODULUS = 1_000_000_000
MAX_ENTRY = 1_000_000
MAX_VALID_INPUT_LENGTH = MAX_N * MAX_N + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = (MAX_N + 1) * 8
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, int, list[list[int]]] | None:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
        or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, modulus = values[0], values[1]
    if not 1 <= n <= MAX_N or not 2 <= modulus <= MAX_MODULUS:
        return None
    if len(values) != 2 + n * n:
        return None
    entries = values[2:]
    if any(not -MAX_ENTRY <= value <= MAX_ENTRY for value in entries):
        return None
    matrix = [
        [entries[row * n + col] % modulus for col in range(n)]
        for row in range(n)
    ]
    return n, modulus, matrix


def _berkowitz(matrix: list[list[int]], modulus: int) -> list[int]:
    """Build each trailing-principal polynomial by a Toeplitz transform."""
    n = len(matrix)
    coefficients = [1]
    for size in range(1, n + 1):
        start = n - size
        a00 = matrix[start][start]
        toeplitz = [1, (-a00) % modulus]
        block = size - 1
        vector = [matrix[start + 1 + row][start] for row in range(block)]
        for power in range(block):
            dot = 0
            for col in range(block):
                dot = (dot + matrix[start][start + 1 + col] * vector[col]) % modulus
            toeplitz.append((-dot) % modulus)
            next_vector = [0] * block
            for row in range(block):
                value = 0
                for col in range(block):
                    value = (value + matrix[start + 1 + row][start + 1 + col]
                             * vector[col]) % modulus
                next_vector[row] = value
            vector = next_vector

        current = [0] * (size + 1)
        for row in range(size + 1):
            total = 0
            for child_degree in range(min(row, size - 1) + 1):
                total = (total + toeplitz[row - child_degree]
                         * coefficients[child_degree]) % modulus
            current[row] = total
        coefficients = current
    return coefficients


def _serialize(coefficients: list[int]) -> bytes:
    return b"".join(coefficient.to_bytes(8, "little", signed=True)
                    for coefficient in coefficients)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    _, modulus, matrix = parsed
    output = _serialize(_berkowitz(matrix, modulus))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
