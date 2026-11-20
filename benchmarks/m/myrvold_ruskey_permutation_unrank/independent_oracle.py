"""Inverse-rank search reference, independent of the unranking traversal."""

from __future__ import annotations

from itertools import permutations
import struct

MIN_N = 0
MAX_N = 8
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 64
WORKSPACE_BYTES = 256
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _rank_by_inverse(permutation: tuple[int, ...]) -> int:
    """Apply the paper's inverse ranking recurrence to one candidate tuple."""
    n = len(permutation)
    values = list(permutation)
    position = [0] * n
    for index, value in enumerate(values):
        position[value] = index

    rank = 0
    place_value = 1
    size = n
    while size > 1:
        last_value = values[size - 1]
        swap_index = position[size - 1]
        values[size - 1], values[swap_index] = values[swap_index], values[size - 1]
        position[last_value], position[size - 1] = position[size - 1], position[last_value]
        rank += last_value * place_value
        place_value *= size
        size -= 1
    return rank


def _find_permutation(n: int, rank: int) -> tuple[int, ...]:
    if n == 0:
        return ()
    for candidate in permutations(range(n)):
        if _rank_by_inverse(candidate) == rank:
            return candidate
    raise AssertionError("rank is outside the permutation domain")


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if len(values) != 2:
        return None
    n, rank = values
    if not MIN_N <= n <= MAX_N:
        return None
    factorial = 1
    for factor in range(2, n + 1):
        factorial *= factor
    if not 0 <= rank < factorial:
        return None
    return n, rank


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Find the permutation by inverse ranking rather than unranking swaps."""
    if (type(output_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or type(input_is_null) is not bool
            or input_length is not None
            and (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return -1, b""
    if input_is_null:
        if values not in (None, [], ()) or input_length not in (None, 0):
            return -1, b""
        return -1, b""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    n, rank = decoded
    required = 8 * n
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, b""
    result = _find_permutation(n, rank)
    payload = struct.pack("<" + "q" * n, *result) if n else b""
    return required, payload
