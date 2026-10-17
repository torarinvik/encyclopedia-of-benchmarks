"""Independent oracle for bounded deterministic single-point crossover."""

from __future__ import annotations

import math
from collections.abc import Sequence


MIN_PARENT_LENGTH = 2
MAX_PARENT_LENGTH = 31
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_PARENT_LENGTH
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 2  # exact-length n=32 rejection
MAX_OUTPUT_ELEMENTS = 2 * MAX_PARENT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _finite_number(value: object) -> float | None:
    if type(value) not in (int, float):
        return None
    number = float(value)
    return number if math.isfinite(number) else None


def _exact_integer(value: object) -> int | None:
    number = _finite_number(value)
    if number is None or number != math.floor(number):
        return None
    return int(number)


def expected_output(values: Sequence[float]) -> list[float] | None:
    """Return concatenated children, or ``None`` for malformed input.

    The packed input is ``[n, j, x1..., x2...]``. ``j`` is the
    prefix length copied from each parent before the suffixes are exchanged.
    """
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH):
        return None

    parent_length = _exact_integer(values[0])
    cut = _exact_integer(values[1])
    if (parent_length is None
            or not MIN_PARENT_LENGTH <= parent_length <= MAX_PARENT_LENGTH
            or cut is None or not 1 <= cut < parent_length
            or len(values) != 2 + 2 * parent_length):
        return None

    first_parent: list[float] = []
    second_parent: list[float] = []
    second_start = 2 + parent_length
    for raw in values[2:second_start]:
        gene = _finite_number(raw)
        if gene is None:
            return None
        first_parent.append(gene)
    for raw in values[second_start:]:
        gene = _finite_number(raw)
        if gene is None:
            return None
        second_parent.append(gene)

    child1 = first_parent[:cut] + second_parent[cut:]
    child2 = second_parent[:cut] + first_parent[cut:]
    return child1 + child2


def expected_abi_result(
    values: Sequence[float],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, list[float]]:
    """Return ABI ``(status, output)`` with input errors taking precedence."""
    output = expected_output(values)
    if output is None:
        return INVALID_RESULT, []
    if (type(output_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, []
    if output_is_null or (capacity is not None and len(output) > capacity):
        return OUTPUT_ERROR, []
    return len(output), output

