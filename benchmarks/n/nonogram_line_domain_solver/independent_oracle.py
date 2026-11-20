"""Independent exhaustive row-tuple reference for nonogram workloads."""

from __future__ import annotations

from typing import Optional, Sequence

from n.nonogram_line_domain_solver.primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    _parse,
    _runs,
)


def solve(values: list[int]) -> Optional[bytes]:
    parsed = _parse(values)
    if parsed is None:
        return None
    height, width, row_clues, column_clues = parsed
    row_candidates = [
        [mask for mask in range(1 << width) if _runs(mask, width) == clue]
        for clue in row_clues
    ]
    column_candidates = [
        [mask for mask in range(1 << height) if _runs(mask, height) == clue]
        for clue in column_clues
    ]
    chosen: list[int] = []

    def extend(row: int) -> bool:
        if row == height:
            return True
        for mask in row_candidates[row]:
            chosen.append(mask)
            viable = True
            prefix_mask = (1 << (row + 1)) - 1
            for column, candidates in enumerate(column_candidates):
                observed = sum(((chosen[r] >> column) & 1) << r for r in range(row + 1))
                if not any((candidate & prefix_mask) == observed for candidate in candidates):
                    viable = False
                    break
            if viable and extend(row + 1):
                return True
            chosen.pop()
        return False

    if not extend(0):
        return None
    return bytes((chosen[row] >> column) & 1
                 for row in range(height) for column in range(width))


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or input_length < 0)
            or input_is_null and (values not in (None, [], ())
                                  or input_length not in (None, 0))
            or not input_is_null and values is not None
            and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or _parse(list(values)) is None):
        return -1, b""
    result = solve(list(values))
    if result is None:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(result):
        return -2, b""
    return len(result), result


def expected_call(values: list[int], capacity: Optional[int] = None) -> tuple[int, bytes]:
    return expected_output(values, capacity)

