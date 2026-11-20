"""Direct weighted-vote definition checked by bounded assignment enumeration."""

from __future__ import annotations

from collections.abc import Sequence

MAX_APPLICANTS = 4
MAX_JOBS = 5
MAX_WEIGHT = 1000
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_APPLICANTS + MAX_APPLICANTS * MAX_JOBS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[int], int, list[list[int]]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    applicants, jobs = values[:2]
    if not 1 <= applicants <= MAX_APPLICANTS or not 1 <= jobs <= MAX_JOBS:
        return None
    if len(values) < 2 + 2 * applicants:
        return None
    weights = list(values[2:2 + applicants])
    lengths = list(values[2 + applicants:2 + 2 * applicants])
    if any(not 1 <= w <= MAX_WEIGHT for w in weights):
        return None
    if any(not 1 <= size <= jobs for size in lengths):
        return None
    if len(values) != 2 + 2 * applicants + sum(lengths):
        return None
    rows: list[list[int]] = []
    cursor = 2 + 2 * applicants
    for size in lengths:
        row = list(values[cursor:cursor + size])
        cursor += size
        if any(not 0 <= job < jobs for job in row) or len(set(row)) != size:
            return None
        rows.append(row)
    return weights, jobs, rows


def _enumerate_assignments(jobs: int, rows: list[list[int]]) -> list[tuple[int, ...]]:
    applicants = len(rows)
    assignment = [-1] * applicants
    results: list[tuple[int, ...]] = []
    used: set[int] = set()

    def visit(a: int) -> None:
        if a == applicants:
            results.append(tuple(assignment))
            return
        for job in rows[a]:
            if job in used:
                continue
            used.add(job)
            assignment[a] = job
            visit(a + 1)
            used.remove(job)
        assignment[a] = jobs + a
        visit(a + 1)

    visit(0)
    return results


def _direct_popular_exists(weights: list[int], jobs: int,
                           preferences: list[list[int]]) -> bool:
    rows = [row + [jobs + a] for a, row in enumerate(preferences)]
    rank = [{job: i for i, job in enumerate(row)} for row in rows]
    assignments = _enumerate_assignments(jobs, rows)

    for candidate in assignments:
        defeated = False
        for challenger in assignments:
            margin = 0
            for a, weight in enumerate(weights):
                candidate_rank = rank[a][candidate[a]]
                challenger_rank = rank[a][challenger[a]]
                if challenger_rank < candidate_rank:
                    margin += weight
                elif challenger_rank > candidate_rank:
                    margin -= weight
            if margin > 0:
                defeated = True
                break
        if not defeated:
            return True
    return False


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    weights, jobs, preferences = parsed
    return int(_direct_popular_exists(weights, jobs, preferences))
