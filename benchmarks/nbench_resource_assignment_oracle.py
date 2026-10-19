"""Bounded NBench resource-assignment oracle (Hungarian tableau method)."""
from __future__ import annotations
import struct
from typing import Sequence

MAX_N = 8
MAX_COST = 1000
MAX_INPUT_LENGTH = 1 + MAX_N * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_N * 4
MAX_ADJUSTMENTS = 2048
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _solve(costs: list[list[int]]) -> list[int] | None:
    n = len(costs)
    a = [row[:] for row in costs]
    for i in range(n):
        m = min(a[i])
        for j in range(n): a[i][j] -= m
    for j in range(n):
        m = min(a[i][j] for i in range(n))
        if m:
            for i in range(n): a[i][j] -= m
    mark = [[0] * n for _ in range(n)]

    def first_assignments() -> int:
        for i in range(n):
            for j in range(n): mark[i][j] = 0
        total = 0
        while True:
            made = 0
            for i in range(n):
                zeros = [j for j in range(n) if a[i][j] == 0 and mark[i][j] == 0]
                if len(zeros) == 1:
                    j = zeros[0]; made += 1; total += 1; mark[i][j] = 1
                    for k in range(n):
                        if k != i and a[k][j] == 0: mark[k][j] = 2
            for j in range(n):
                zeros = [i for i in range(n) if a[i][j] == 0 and mark[i][j] == 0]
                if len(zeros) == 1:
                    i = zeros[0]; made += 1; total += 1; mark[i][j] = 1
                    for k in range(n):
                        if k != j and a[i][k] == 0: mark[i][k] = 2
            if made == 0: break
        if total == n: return total
        for i in range(n):
            chosen = next((j for j in range(n) if a[i][j] == 0 and mark[i][j] == 0), -1)
            if chosen >= 0:
                mark[i][chosen] = 1; total += 1
                for k in range(n):
                    if k != chosen and a[i][k] == 0: mark[i][k] = 2
                for k in range(n):
                    if k != i and a[k][chosen] == 0: mark[k][chosen] = 2
        return total

    def second_assignments() -> None:
        row_lines = [0] * n
        col_lines = [0] * n
        for i in range(n): row_lines[i] = 0 if any(mark[i][j] == 1 for j in range(n)) else 1
        while True:
            new_rows = 0
            for i in range(n):
                if row_lines[i]:
                    for j in range(n):
                        if a[i][j] == 0: col_lines[j] = 1
            for j in range(n):
                if col_lines[j]:
                    for i in range(n):
                        if mark[i][j] == 1 and row_lines[i] != 1:
                            row_lines[i] = 1; new_rows += 1
            if new_rows == 0: break
        candidates = [a[i][j] for i in range(n) if row_lines[i] for j in range(n) if not col_lines[j]]
        if not candidates: raise ArithmeticError
        smallest = min(candidates)
        for i in range(n):
            for j in range(n):
                if row_lines[i] and not col_lines[j]: a[i][j] -= smallest
                elif not row_lines[i] and col_lines[j]: a[i][j] += smallest

    for _ in range(MAX_ADJUSTMENTS + 1):
        if first_assignments() == n:
            result = [next((j for j in range(n) if mark[i][j] == 1), -1) for i in range(n)]
            if -1 in result or len(set(result)) != n: return None
            return result
        second_assignments()
    return None


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (tuple, list))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT, b""
    if any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values): return -1, b""
    if input_length is not None and input_length != len(values): return INVALID_RESULT, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + n*n or any(x < 0 or x > MAX_COST for x in values[1:]): return INVALID_RESULT, b""
    assignment = _solve([list(values[1+i*n:1+(i+1)*n]) for i in range(n)])
    if assignment is None: return INVALID_RESULT, b""
    result = b"".join(struct.pack("<i", col) for col in assignment)
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return OUTPUT_ERROR, b""
    return len(result), result
