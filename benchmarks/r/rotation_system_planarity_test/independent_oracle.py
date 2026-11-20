"""Independent Wagner forbidden-minor verifier for six-vertex graphs."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 1
MAX_VERTICES = 6
MAX_EDGES = 15
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _is_k5_minor(n: int, adjacent: list[list[bool]]) -> bool:
    if n < 5:
        return False
    if n == 5:
        return all(adjacent[u][v] for u in range(5) for v in range(u + 1, 5))

    # A five-branch-set model on six vertices either leaves one vertex unused,
    # or contracts one edge into a two-vertex branch set.
    for omitted in range(6):
        singles = [v for v in range(6) if v != omitted]
        if all(adjacent[u][v] for i, u in enumerate(singles)
               for v in singles[i + 1:]):
            return True
    for left in range(6):
        for right in range(left + 1, 6):
            if not adjacent[left][right]:
                continue
            singles = [v for v in range(6) if v != left and v != right]
            if all(adjacent[u][v] for i, u in enumerate(singles)
                   for v in singles[i + 1:]) and all(
                       adjacent[left][v] or adjacent[right][v] for v in singles
                   ):
                return True
    return False


def _is_k33_minor(n: int, adjacent: list[list[bool]]) -> bool:
    if n != 6:
        return False
    for left_mask in range(1 << n):
        if left_mask & 1 == 0 or left_mask.bit_count() != 3:
            continue
        left = [v for v in range(n) if (left_mask >> v) & 1]
        right = [v for v in range(n) if not ((left_mask >> v) & 1)]
        if all(adjacent[u][v] for u in left for v in right):
            return True
    return False


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    n, m = values[0], values[1]
    if not MIN_VERTICES <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return INVALID_RESULT
    if len(values) != 2 + 2 * m:
        return INVALID_RESULT
    adjacent = [[False] * n for _ in range(n)]
    seen: set[tuple[int, int]] = set()
    for at in range(2, len(values), 2):
        u, v = values[at], values[at + 1]
        if not 0 <= u < v < n or (u, v) in seen:
            return INVALID_RESULT
        seen.add((u, v))
        adjacent[u][v] = adjacent[v][u] = True
    return 0 if _is_k5_minor(n, adjacent) or _is_k33_minor(n, adjacent) else 1
