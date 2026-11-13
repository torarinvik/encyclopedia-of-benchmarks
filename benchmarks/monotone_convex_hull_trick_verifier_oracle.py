"""Independent all-lines scan oracle for the monotone CHT benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LINES = 32
MAX_QUERIES = 32
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_LINES + MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -(1 << 63)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Validate the packed contract, then scan every line for every query."""
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        return INVALID_RESULT

    number_of_lines, number_of_queries = values[0], values[1]
    if not 1 <= number_of_lines <= MAX_LINES or not 0 <= number_of_queries <= MAX_QUERIES:
        return INVALID_RESULT
    if len(values) != 2 + number_of_lines * 2 + number_of_queries:
        return INVALID_RESULT

    lines = [tuple(values[2 + 2 * i:4 + 2 * i]) for i in range(number_of_lines)]
    if any(
        type(slope) is not int or type(intercept) is not int
        or not -1_000 <= slope <= 1_000
        or not -10_000 <= intercept <= 10_000
        for slope, intercept in lines
    ):
        return INVALID_RESULT
    if any(lines[i][0] <= lines[i + 1][0] for i in range(number_of_lines - 1)):
        return INVALID_RESULT

    query_start = 2 + 2 * number_of_lines
    query_xs = values[query_start:]
    if any(type(x) is not int or not -1_000 <= x <= 1_000 for x in query_xs):
        return INVALID_RESULT
    if any(query_xs[i] > query_xs[i + 1] for i in range(number_of_queries - 1)):
        return INVALID_RESULT

    total = 0
    for position, x in enumerate(query_xs, start=1):
        minimum = min(slope * x + intercept for slope, intercept in lines)
        total += position * minimum
    if total <= I64_MIN or total > I64_MAX:
        return INVALID_RESULT
    return total
