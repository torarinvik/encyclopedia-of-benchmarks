"""Independent exact-product reference for a supplied Freivalds trace."""
from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_ROUNDS = 8
MAX_ENTRY = 3
MAX_PARSEABLE_INPUT_LENGTH = 259


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n, rounds = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= rounds <= MAX_ROUNDS:
        return None
    expected_length = 2 + 3 * n * n + rounds * n
    if len(values) != expected_length:
        return None
    cursor = 2
    matrices = []
    for _ in range(3):
        entries = values[cursor:cursor + n * n]
        if any(not -MAX_ENTRY <= entry <= MAX_ENTRY for entry in entries):
            return None
        matrices.append([list(entries[row * n:(row + 1) * n]) for row in range(n)])
        cursor += n * n
    vectors = []
    while cursor < len(values):
        vector = values[cursor:cursor + n]
        if any(sign not in (-1, 1) for sign in vector):
            return None
        vectors.append(vector)
        cursor += n
    return n, rounds, *matrices, vectors


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, rounds, a, b, c, signs = parsed
    product_difference = [
        [sum(a[row][inner] * b[inner][col] for inner in range(n)) - c[row][col]
         for col in range(n)]
        for row in range(n)
    ]
    for vector in signs[:rounds]:
        if any(sum(product_difference[row][col] * vector[col] for col in range(n)) != 0
               for row in range(n)):
            return 0
    return 1
