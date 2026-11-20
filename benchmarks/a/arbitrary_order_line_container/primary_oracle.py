"""Bounded Nyaan-style breakpoint line container with arbitrary line insertion."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 32
MAX_VALID_INPUT_LENGTH = 98
MAX_PARSEABLE_INPUT_LENGTH = 99
COEFFICIENT_LIMIT = 1000
QUERY_LIMIT = 1000
CHECKSUM_OFFSET = 2_000_001
BREAKPOINT_INFINITY = 10**15
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    objective, operation_count = values[:2]
    if objective not in (0, 1) or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 2 + 3 * operation_count or len(values) > MAX_VALID_INPUT_LENGTH:
        return None
    operations: list[tuple[int, int, int]] = []
    seen_line = False
    cursor = 2
    for _ in range(operation_count):
        opcode, first, second = values[cursor:cursor + 3]
        cursor += 3
        if opcode == 0:
            if not -COEFFICIENT_LIMIT <= first <= COEFFICIENT_LIMIT:
                return None
            if not -COEFFICIENT_LIMIT <= second <= COEFFICIENT_LIMIT:
                return None
            seen_line = True
        elif opcode == 1:
            if not seen_line or not -QUERY_LIMIT <= first <= QUERY_LIMIT or second != 0:
                return None
        else:
            return None
        operations.append((opcode, first, second))
    return objective, operations


def _floor_div(numerator: int, denominator: int) -> int:
    return numerator // denominator


def _intersection(left: tuple[int, int, int], right: tuple[int, int, int]) -> int:
    return _floor_div(left[1] - right[1], right[0] - left[0])


def _erase(lines: list[tuple[int, int, int]], position: int) -> None:
    del lines[position]


def _insert_line(lines: list[tuple[int, int, int]], slope: int,
                 intercept: int) -> None:
    position = 0
    while position < len(lines) and lines[position][0] < slope:
        position += 1
    if position < len(lines) and lines[position][0] == slope:
        if lines[position][1] >= intercept:
            return
        _erase(lines, position)

    lines.insert(position, (slope, intercept, BREAKPOINT_INFINITY))
    active = position
    while active + 1 < len(lines):
        breakpoint = _intersection(lines[active], lines[active + 1])
        line = lines[active]
        lines[active] = (line[0], line[1], breakpoint)
        if breakpoint >= lines[active + 1][2]:
            _erase(lines, active + 1)
        else:
            break
    if active + 1 == len(lines):
        line = lines[active]
        lines[active] = (line[0], line[1], BREAKPOINT_INFINITY)

    if active > 0:
        breakpoint = _intersection(lines[active - 1], lines[active])
        previous = lines[active - 1]
        lines[active - 1] = (previous[0], previous[1], breakpoint)
        if breakpoint >= lines[active][2]:
            _erase(lines, active)
            active -= 1
            if active + 1 < len(lines):
                line = lines[active]
                lines[active] = (line[0], line[1], _intersection(line, lines[active + 1]))
            else:
                line = lines[active]
                lines[active] = (line[0], line[1], BREAKPOINT_INFINITY)
            cursor = active
        else:
            cursor = active - 1

        while cursor > 0 and lines[cursor - 1][2] >= lines[cursor][2]:
            _erase(lines, cursor)
            cursor -= 1
            active -= 1
            if cursor + 1 < len(lines):
                line = lines[cursor]
                lines[cursor] = (line[0], line[1], _intersection(line, lines[cursor + 1]))
            else:
                line = lines[cursor]
                lines[cursor] = (line[0], line[1], BREAKPOINT_INFINITY)


def _query(lines: list[tuple[int, int, int]], x: int, objective: int) -> int:
    low = 0
    high = len(lines)
    while low < high:
        middle = (low + high) // 2
        if lines[middle][2] < x:
            low = middle + 1
        else:
            high = middle
    slope, intercept, _ = lines[low]
    return (slope * x + intercept) * objective


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    objective_mode, operations = decoded
    objective = 1 if objective_mode == 1 else -1
    lines: list[tuple[int, int, int]] = []
    checksum = 0
    query_index = 0
    for opcode, first, second in operations:
        if opcode == 0:
            _insert_line(lines, first * objective, second * objective)
        else:
            optimum = _query(lines, first, objective)
            checksum += (query_index + 1) * (optimum + CHECKSUM_OFFSET)
            query_index += 1
    return checksum
