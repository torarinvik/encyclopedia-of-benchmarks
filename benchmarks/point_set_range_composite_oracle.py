"""Direct-scan oracle for bounded point-set/range affine composition."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998_244_353
MAX_N = 16
MAX_OPERATIONS = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_N + 4 * MAX_OPERATIONS
INVALID_RESULT = -1
TASK_URL = "https://judge.yosupo.jp/problem/point_set_range_composite"
PROPOSAL_URL = "https://github.com/yosupo06/library-checker-problems/issues/122"
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return a query checksum by applying each queried map in array order."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH
    ):
        return INVALID_RESULT
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if (not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    n, operation_count = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    if len(values) != 2 + 2 * n + 4 * operation_count:
        return INVALID_RESULT

    functions: list[tuple[int, int]] = []
    cursor = 2
    for _ in range(n):
        a, b = values[cursor:cursor + 2]
        if not 0 <= a < MODULUS or not 0 <= b < MODULUS:
            return INVALID_RESULT
        functions.append((a, b))
        cursor += 2

    checksum = 0
    query_number = 0
    for _ in range(operation_count):
        opcode, first, second, third = values[cursor:cursor + 4]
        cursor += 4
        if opcode == 0:
            if (not 0 <= first < n
                    or not 0 <= second < MODULUS
                    or not 0 <= third < MODULUS):
                return INVALID_RESULT
            functions[first] = (second, third)
        elif opcode == 1:
            left, right, x = first, second, third
            if not 0 <= left <= right <= n or not 0 <= x < MODULUS:
                return INVALID_RESULT
            result = x
            for a, b in functions[left:right]:
                result = (a * result + b) % MODULUS
            query_number += 1
            checksum = (checksum + query_number * result) % MODULUS
        else:
            return INVALID_RESULT
    return checksum if cursor == len(values) else INVALID_RESULT
