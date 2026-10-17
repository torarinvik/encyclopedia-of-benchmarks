"""Independent stable-matching oracle for bounded complete preference lists."""
from __future__ import annotations

import itertools
import struct

MAX_N = 8
MAX_INPUT_LENGTH = 1 + 2 * MAX_N * MAX_N
MAX_OUTPUT_BYTES = 16 * MAX_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _men_optimal_matching(
    men_preferences: list[list[int]], women_preferences: list[list[int]]
) -> tuple[int, ...]:
    """Enumerate stable assignments, then select the men's componentwise optimum."""
    n = len(men_preferences)
    if n == 0:
        return ()
    men_rank = [
        {woman: rank for rank, woman in enumerate(row)} for row in men_preferences
    ]
    women_rank = [
        {man: rank for rank, man in enumerate(row)} for row in women_preferences
    ]
    stable: list[tuple[int, ...]] = []
    for assignment in itertools.permutations(range(n)):
        inverse = [0] * n
        for man, woman in enumerate(assignment):
            inverse[woman] = man
        blocked = False
        for man in range(n):
            current_woman = assignment[man]
            for woman in range(n):
                if men_rank[man][woman] >= men_rank[man][current_woman]:
                    continue
                current_man = inverse[woman]
                if women_rank[woman][man] < women_rank[woman][current_man]:
                    blocked = True
                    break
            if blocked:
                break
        if not blocked:
            stable.append(assignment)

    return min(stable, key=lambda assignment: tuple(
        men_rank[man][woman] for man, woman in enumerate(assignment)
    ))


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return status and canonical pairs encoded as little-endian signed i64s."""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1, b""

    n = values[0]
    if not 0 <= n <= MAX_N:
        return -1, b""
    required_length = 1 + 2 * n * n
    if len(values) != required_length:
        return -1, b""

    men_rows: list[list[int]] = []
    women_rows: list[list[int]] = []
    side_size = n * n
    for side_start, rows in ((1, men_rows), (1 + side_size, women_rows)):
        for man_or_woman in range(n):
            row_start = side_start + man_or_woman * n
            row = list(values[row_start : row_start + n])
            if sorted(row) != list(range(n)):
                return -1, b""
            rows.append(row)

    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""
    required_bytes = 16 * n
    if output_is_null or (output_capacity is not None and output_capacity < required_bytes):
        return -2, b""

    assignment = _men_optimal_matching(men_rows, women_rows)
    output = b"".join(
        struct.pack("<q", identifier)
        for man, woman in enumerate(assignment)
        for identifier in (man, woman)
    )
    return len(output), output
