"""Bounded Algorithm X oracle for the general exact-cover benchmark."""

from __future__ import annotations


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not 2 <= len(values) <= 10
            or any(type(value) is not int for value in values)):
        return -1, b""
    columns, row_count = values[:2]
    if not 1 <= columns <= 8 or not 0 <= row_count <= 8 or len(values) != row_count + 2:
        return -1, b""
    limit = (1 << columns) - 1
    rows = values[2:]
    if any(mask <= 0 or mask & ~limit for mask in rows):
        return -1, b""
    solutions: list[int] = []

    def search(covered: int, selected: int) -> None:
        if covered == limit:
            solutions.append(selected)
            return
        best: list[int] | None = None
        for column in range(columns):
            bit = 1 << column
            if covered & bit:
                continue
            candidates = [i for i, row in enumerate(rows)
                          if row & bit and row & covered == 0]
            if not candidates:
                return
            if best is None or len(candidates) < len(best):
                best = candidates
        assert best is not None
        for index in best:
            search(covered | rows[index], selected | (1 << index))

    search(0, 0)
    solutions.sort()
    return len(solutions), bytes(solutions)
