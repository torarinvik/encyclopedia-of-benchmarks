"""Direct-scan oracle for the bounded online Li Chao tree benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 512
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
DOMAIN_LOW = -1_000_000
DOMAIN_HIGH = 1_000_000
COEFFICIENT_LIMIT = 1_000
CHECKSUM_OFFSET = 1_000_001_001
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

SOURCE_BASIS = [
    {
        "organization": "CP-Algorithms",
        "title": "Convex hull trick and Li Chao tree",
        "url": "https://cp-algorithms.com/geometry/convex_hull_trick.html",
        "role": "algorithm_description",
    },
    {
        "organization": "Library Checker",
        "title": "Line Add Get Min",
        "url": "https://judge.yosupo.jp/problem/line_add_get_min",
        "role": "problem_taxonomy",
    },
]


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the weighted query checksum, or -1 for an invalid packed trace.

    This reference keeps every added line and scans them at each query; it does
    not use a tree or share the benchmark implementation's search structure.
    """
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return INVALID_RESULT
    if input_is_null:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if len(values) < 1 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) != 1 + 3 * operation_count:
        return INVALID_RESULT

    lines: list[tuple[int, int]] = []
    answers: list[int] = []
    for operation in range(operation_count):
        offset = 1 + 3 * operation
        opcode, first, second = values[offset:offset + 3]
        if opcode == 0:
            if not -COEFFICIENT_LIMIT <= first <= COEFFICIENT_LIMIT:
                return INVALID_RESULT
            if not -COEFFICIENT_LIMIT <= second <= COEFFICIENT_LIMIT:
                return INVALID_RESULT
            lines.append((first, second))
        elif opcode == 1:
            if not DOMAIN_LOW <= first <= DOMAIN_HIGH or second != 0 or not lines:
                return INVALID_RESULT
            answers.append(min(slope * first + intercept for slope, intercept in lines))
        else:
            return INVALID_RESULT

    return sum(index * (answer + CHECKSUM_OFFSET)
               for index, answer in enumerate(answers, start=1))
